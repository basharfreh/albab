from django.conf import settings


class BaseOtpBackend:
    """Pluggable OTP delivery interface — swap in a real SMS gateway without touching the flow."""

    def send(self, phone: str, code: str) -> None:
        raise NotImplementedError


class ConsoleOtpBackend(BaseOtpBackend):
    """Dev backend: prints the code. The view also returns it in the response when DEBUG=True."""

    def send(self, phone: str, code: str) -> None:
        print(f"[OTP] {phone}: {code}")


_BACKENDS = {"console": ConsoleOtpBackend}


def get_otp_backend() -> BaseOtpBackend:
    backend_cls = _BACKENDS[settings.OTP_BACKEND]
    return backend_cls()
