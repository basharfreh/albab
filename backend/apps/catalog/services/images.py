import io

from django.core.exceptions import ValidationError
from django.core.files.base import ContentFile
from PIL import Image

THUMBNAIL_WIDTH = 800
MAX_IMAGES_PER_LISTING = 15
MAX_IMAGE_SIZE_BYTES = 8 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}


def validate_image_file(file) -> None:
    if file.size > MAX_IMAGE_SIZE_BYTES:
        raise ValidationError("حجم الصورة أكبر من 8 ميغابايت.")
    if getattr(file, "content_type", None) not in ALLOWED_CONTENT_TYPES:
        raise ValidationError("صيغة الصورة غير مدعومة. الصيغ المسموحة: JPG، PNG، WEBP.")


def make_thumbnail(file) -> ContentFile:
    """Generate an up-to-800px-wide WebP thumbnail. Never upscales a smaller original."""
    file.seek(0)
    image = Image.open(file)
    image = image.convert("RGB")

    ratio = min(1.0, THUMBNAIL_WIDTH / image.width)
    target_size = (round(image.width * ratio), round(image.height * ratio))
    resized = image.resize(target_size)

    buffer = io.BytesIO()
    resized.save(buffer, format="WEBP", quality=80)
    buffer.seek(0)
    return ContentFile(buffer.read(), name="thumb.webp")
