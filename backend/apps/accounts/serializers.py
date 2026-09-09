from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from apps.accounts.models import OtpPurpose, User, UserRole
from apps.accounts.utils import normalize_phone_field


class UserSerializer(serializers.ModelSerializer):
    """Public profile — safe to show for any user (e.g. a listing's owner block)."""

    class Meta:
        model = User
        fields = ["id", "name", "role", "avatar", "agency_name", "agency_logo"]
        read_only_fields = fields


class MeSerializer(UserSerializer):
    """The authenticated user's own profile — adds fields never exposed for other users."""

    unread_messages = serializers.SerializerMethodField()
    unread_notifications = serializers.SerializerMethodField()

    class Meta(UserSerializer.Meta):
        fields = UserSerializer.Meta.fields + [
            "phone",
            "whatsapp_phone",
            "is_phone_verified",
            "unread_messages",
            "unread_notifications",
        ]
        read_only_fields = ["id", "phone", "role", "is_phone_verified"]

    def get_unread_messages(self, obj):
        from django.db.models import Q

        from apps.engagement.models import Conversation

        conversations = Conversation.objects.filter(Q(seeker=obj) | Q(owner=obj))
        return sum(
            conversation.messages.filter(read_at__isnull=True).exclude(sender=obj).count()
            for conversation in conversations
        )

    def get_unread_notifications(self, obj):
        from apps.engagement.models import Notification

        return Notification.objects.filter(user=obj, read_at__isnull=True).count()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(choices=[UserRole.SEEKER, UserRole.OWNER, UserRole.AGENCY])
    # Skip the auto-generated UniqueValidator: it would run on the raw,
    # un-normalized phone before validate_phone normalizes it, so it can
    # miss a duplicate and let an IntegrityError reach the DB instead.
    phone = serializers.CharField(validators=[])

    class Meta:
        model = User
        fields = ["id", "phone", "name", "password", "role", "agency_name"]
        read_only_fields = ["id"]

    def validate_phone(self, value):
        phone = normalize_phone_field(value)
        if User.objects.filter(phone=phone).exists():
            raise serializers.ValidationError("رقم الهاتف مستخدم مسبقاً.")
        return phone

    def validate_password(self, value):
        try:
            validate_password(value)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc
        return value

    def validate(self, attrs):
        if attrs.get("role") == UserRole.AGENCY and not attrs.get("agency_name"):
            raise serializers.ValidationError(
                {"agency_name": ["اسم المكتب مطلوب لحساب المكتب العقاري."]}
            )
        return attrs

    def create(self, validated_data):
        password = validated_data.pop("password")
        return User.objects.create_user(password=password, **validated_data)


class PhoneTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Login with phone + password, tolerating any of the input phone formats."""

    def validate(self, attrs):
        try:
            attrs[self.username_field] = normalize_phone_field(attrs[self.username_field])
        except serializers.ValidationError:
            pass  # let the normal auth failure below report a uniform error
        try:
            data = super().validate(attrs)
        except AuthenticationFailed as exc:
            raise AuthenticationFailed(
                "رقم الهاتف أو كلمة المرور غير صحيحة.", exc.get_codes()
            ) from exc
        if self.user.is_blocked:
            raise AuthenticationFailed("تم حظر هذا الحساب.")
        return data


class AdminUserSerializer(UserSerializer):
    """UC-55: what an admin sees when managing users."""

    class Meta(UserSerializer.Meta):
        fields = UserSerializer.Meta.fields + [
            "phone",
            "is_phone_verified",
            "is_blocked",
            "created_at",
        ]
        read_only_fields = fields


class OtpRequestSerializer(serializers.Serializer):
    phone = serializers.CharField()
    purpose = serializers.ChoiceField(choices=OtpPurpose.choices, default=OtpPurpose.REGISTER)

    def validate_phone(self, value):
        return normalize_phone_field(value)


class OtpVerifySerializer(OtpRequestSerializer):
    code = serializers.CharField(max_length=6, min_length=6)
