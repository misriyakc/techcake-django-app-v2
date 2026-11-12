import os

from django.core.cache import cache
from django.http import JsonResponse
from django.shortcuts import render


def index(request):
    try:
        visits = cache.incr("techcake:visits")
    except ValueError:
        cache.set("techcake:visits", 1)
        visits = 1
    except Exception:
        visits = None

    return render(request, "congrats/index.html", {"visits": visits})


def health(request):
    return JsonResponse({
        "status": "ok",
        "sha": os.environ.get("APP_VERSION", "unknown")
    })
