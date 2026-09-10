from django.db import models


class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class StaticPage(TimeStampedModel):
    """UC-59's admin-editable "static content" (e.g. about/terms/privacy) — a generic
    slug + bilingual title/body rather than one hardcoded field per page, since the brief
    doesn't fix the exact set of pages. Lives in `common`, not `catalog`, since it's
    site-wide content, not listing-domain data."""

    slug = models.SlugField(unique=True)
    title_ar = models.CharField(max_length=200)
    title_en = models.CharField(max_length=200, blank=True)
    body_ar = models.TextField(blank=True)
    body_en = models.TextField(blank=True)

    class Meta:
        ordering = ["slug"]

    def __str__(self):
        return self.slug
