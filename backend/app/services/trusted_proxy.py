"""Resolve the real client address behind the reverse proxy — and only behind it.

Synology Web Station reaches the API through the published port, so inside the container
every request comes from the compose network's gateway. Its portal config sets
``X-Real-IP $remote_addr`` and ``X-Forwarded-Proto $scheme``, but it does **not** set
``X-Forwarded-For``: that header reaches the app exactly as the client wrote it. So:

- ``X-Forwarded-For`` is never read, by the app or by uvicorn (``--no-proxy-headers`` in
  docker-compose.prod.yml). Trusting it — leftmost hop or rightmost — lets a client pick
  its own rate-limit bucket. That was the 2026-09-13 finding, and its first fix
  (``FORWARDED_ALLOW_IPS``) failed in production for exactly this reason.
- ``X-Real-IP`` and ``X-Forwarded-Proto`` are believed only when the TCP peer is one of
  ``TRUSTED_PROXY_IPS``. Web Station overwrites ``X-Real-IP`` with the address it accepted
  the connection from, so a client cannot choose it; a caller reaching the port without
  the proxy is not a trusted peer, so its headers are ignored.

After this middleware ``request.client.host`` is the address to rate-limit on, and
``client_ip()`` needs nothing else. See .llmwiki/Security.md.
"""

from __future__ import annotations

import contextlib
import ipaddress

from starlette.types import ASGIApp, Receive, Scope, Send

_SCHEMES = {"http": ("http", "ws"), "https": ("https", "wss")}


class TrustedProxyMiddleware:
    def __init__(self, app: ASGIApp, trusted_ips: list[str]) -> None:
        self.app = app
        self.trusted = frozenset(trusted_ips)

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] in ("http", "websocket") and self.trusted:
            peer = scope.get("client")
            if peer is not None and peer[0] in self.trusted:
                scope = self._resolve(scope, peer[1])
        await self.app(scope, receive, send)

    @staticmethod
    def _resolve(scope: Scope, peer_port: int) -> Scope:
        headers = dict(scope["headers"])  # the proxy sets each of these once
        scope = dict(scope)
        real_ip = headers.get(b"x-real-ip", b"").decode("latin1").strip()
        # Absent or malformed: keep the proxy's own address.
        with contextlib.suppress(ValueError):
            scope["client"] = (str(ipaddress.ip_address(real_ip)), peer_port)
        proto = headers.get(b"x-forwarded-proto", b"").decode("latin1").strip().lower()
        if proto in _SCHEMES:
            http_scheme, ws_scheme = _SCHEMES[proto]
            scope["scheme"] = ws_scheme if scope["type"] == "websocket" else http_scheme
        return scope
