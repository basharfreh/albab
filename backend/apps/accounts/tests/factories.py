import factory

from apps.accounts.models import User, UserRole


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User
        django_get_or_create = ("phone",)
        skip_postgeneration_save = True

    phone = factory.Sequence(lambda n: f"+9639000{n:05d}")
    name = factory.Faker("name")
    role = UserRole.SEEKER
    is_phone_verified = True

    @factory.post_generation
    def password(self, create, extracted, **kwargs):
        self.set_password(extracted or "Testpass123")
        if create:
            self.save()
