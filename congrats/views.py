from django.core.cache import cache
from django.shortcuts import render


def index(request):
    # Visit counter backed by the cache. When REDIS_URL is configured the
    # cache is Redis, so this count is shared across containers and survives
    # app restarts — a simple, visible proof that Redis is wired in.
    try:
        visits = cache.incr("techcake:visits")
    except ValueError:
        cache.set("techcake:visits", 1)
        visits = 1
    except Exception:
        visits = None  # cache unavailable; page still renders

    return render(request, "congrats/index.html", {"visits": visits})
