import io

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from PIL import Image as PILImage
from rest_framework.test import APIClient

from apps.accounts.tests.factories import UserFactory
from apps.catalog.tests.factories import ListingFactory


def _make_test_image(color=(200, 30, 30), fmt="JPEG"):
    buffer = io.BytesIO()
    PILImage.new("RGB", (400, 300), color).save(buffer, format=fmt)
    buffer.seek(0)
    content_type = f"image/{'jpeg' if fmt == 'JPEG' else fmt.lower()}"
    return SimpleUploadedFile(f"test.{fmt.lower()}", buffer.read(), content_type=content_type)


@pytest.mark.django_db
class TestListingImages:
    def test_upload_creates_thumbnail_and_sets_first_as_cover(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner)
        client = APIClient()
        client.force_authenticate(owner)

        response = client.post(
            reverse("listing-images", args=[listing.id]),
            {"image": _make_test_image()},
            format="multipart",
        )
        assert response.status_code == 201
        image = listing.images.first()
        assert image.is_cover is True
        assert image.thumbnail

    def test_upload_rejects_non_image_file(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner)
        client = APIClient()
        client.force_authenticate(owner)

        bad_file = SimpleUploadedFile("test.txt", b"not an image", content_type="text/plain")
        response = client.post(
            reverse("listing-images", args=[listing.id]),
            {"image": bad_file},
            format="multipart",
        )
        assert response.status_code == 400

    def test_max_15_images_enforced(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner)
        for i in range(15):
            listing.images.create(image=f"placeholder_{i}.jpg")

        client = APIClient()
        client.force_authenticate(owner)
        response = client.post(
            reverse("listing-images", args=[listing.id]),
            {"image": _make_test_image()},
            format="multipart",
        )
        assert response.status_code == 400

    def test_non_owner_cannot_upload_images(self):
        owner = UserFactory(role="owner")
        other = UserFactory(role="owner")
        listing = ListingFactory(owner=owner)
        client = APIClient()
        client.force_authenticate(other)

        response = client.post(
            reverse("listing-images", args=[listing.id]),
            {"image": _make_test_image()},
            format="multipart",
        )
        assert response.status_code == 404

    def test_deleting_cover_promotes_next_image(self):
        owner = UserFactory(role="owner")
        listing = ListingFactory(owner=owner)
        first = listing.images.create(image="a.jpg", sort_order=0, is_cover=True)
        second = listing.images.create(image="b.jpg", sort_order=1, is_cover=False)

        client = APIClient()
        client.force_authenticate(owner)
        response = client.delete(reverse("listing-image-detail", args=[listing.id, first.id]))
        assert response.status_code == 204
        second.refresh_from_db()
        assert second.is_cover is True
