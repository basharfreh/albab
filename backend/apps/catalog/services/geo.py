import hashlib
import math

import requests
from django.core.cache import cache

from apps.catalog.models import Neighborhood

NOMINATIM_BASE_URL = "https://nominatim.openstreetmap.org"
USER_AGENT = "AlBabRealEstate/0.1 (contact: support@albab.example)"
# left,top,right,bottom = min_lon,max_lat,max_lon,min_lat, per Nominatim's viewbox order.
AL_BAB_VIEWBOX = "37.35,36.60,37.60,36.42"
CACHE_TTL_SECONDS = 60 * 60 * 24


def search_places(query: str) -> list[dict]:
    cache_key = f"geo:search:{hashlib.sha256(query.encode()).hexdigest()}"
    cached = cache.get(cache_key)
    if cached is not None:
        return cached

    response = requests.get(
        f"{NOMINATIM_BASE_URL}/search",
        params={
            "q": query,
            "format": "jsonv2",
            "viewbox": AL_BAB_VIEWBOX,
            "bounded": 1,
            "limit": 5,
        },
        headers={"User-Agent": USER_AGENT},
        timeout=5,
    )
    response.raise_for_status()
    results = [
        {
            "display_name": item["display_name"],
            "lat": float(item["lat"]),
            "lng": float(item["lon"]),
        }
        for item in response.json()
    ]
    cache.set(cache_key, results, CACHE_TTL_SECONDS)
    return results


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    earth_radius_km = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * earth_radius_km * math.asin(math.sqrt(a))


def nearest_neighborhood(lat: float, lng: float) -> Neighborhood | None:
    nearest = None
    nearest_distance = None
    for neighborhood in Neighborhood.objects.filter(is_active=True):
        distance = _haversine_km(
            lat, lng, float(neighborhood.center_lat), float(neighborhood.center_lng)
        )
        if nearest_distance is None or distance < nearest_distance:
            nearest = neighborhood
            nearest_distance = distance
    return nearest
