from django.contrib import admin
from django.http import JsonResponse
from django.urls import path


def healthz(request):
    return JsonResponse({"status": "ok"})


def readyz(request):
    from django.db import connections
    try:
        connections["default"].cursor()
    except Exception as exc:  # noqa: BLE001
        return JsonResponse({"status": "not ready", "error": str(exc)}, status=503)
    return JsonResponse({"status": "ready"})


urlpatterns = [
    path("admin/", admin.site.urls),
    path("healthz/", healthz),
    path("readyz/", readyz),
]
