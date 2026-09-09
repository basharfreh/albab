class BasePushBackend:
    def send(self, notification):
        raise NotImplementedError


class NoOpPushBackend(BasePushBackend):
    """No real push credentials yet (deferred to P12/FCM). Swap behind this interface."""

    def send(self, notification):
        return None


def get_push_backend():
    return NoOpPushBackend()
