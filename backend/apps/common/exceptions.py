from rest_framework.views import exception_handler


def api_exception_handler(exc, context):
    """Normalize DRF errors to {"detail": "..."} or {"field": ["..."]}."""
    response = exception_handler(exc, context)
    if response is None:
        return None

    data = response.data
    if isinstance(data, dict) and "non_field_errors" in data and len(data) == 1:
        response.data = {"detail": " ".join(str(m) for m in data["non_field_errors"])}
    elif isinstance(data, list):
        response.data = {"detail": " ".join(str(m) for m in data)}

    return response
