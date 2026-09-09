import pytest
from django.core.cache import cache


@pytest.fixture(autouse=True)
def _clear_cache():
    """Throttle counters and the geo-search cache live in Redis, not the DB — pytest-django
    rolls back the database between tests but never touches this, so without a manual clear
    a throttle scope shared across tests (e.g. "auth") would accumulate hits across the whole
    run instead of resetting per test."""
    cache.clear()
    yield
    cache.clear()
