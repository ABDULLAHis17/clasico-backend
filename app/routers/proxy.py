from fastapi import APIRouter, Response, HTTPException, Query
from fastapi.responses import RedirectResponse
import urllib.request
import urllib.error
import ssl
import functools
import hashlib
import os
import time

router = APIRouter(prefix="/proxy", tags=["Proxy"])

# Simple disk cache directory
CACHE_DIR = "/tmp/image_cache"
os.makedirs(CACHE_DIR, exist_ok=True)

# In-memory LRU cache for small images (max 200 entries)
_mem_cache: dict = {}
_MAX_MEM_CACHE = 200


def _cache_key(url: str) -> str:
    return hashlib.md5(url.encode()).hexdigest()


def _get_cached(url: str):
    """Check memory cache first, then disk cache."""
    key = _cache_key(url)

    # Memory cache
    if key in _mem_cache:
        return _mem_cache[key]

    # Disk cache
    disk_path = os.path.join(CACHE_DIR, key)
    if os.path.exists(disk_path):
        try:
            with open(disk_path, "rb") as f:
                data = f.read()
            # Promote to memory cache
            if len(_mem_cache) < _MAX_MEM_CACHE:
                _mem_cache[key] = data
            return data
        except Exception:
            pass
    return None


def _set_cached(url: str, data: bytes):
    """Save to both memory and disk cache."""
    key = _cache_key(url)

    # Memory cache
    if len(_mem_cache) >= _MAX_MEM_CACHE:
        # Evict oldest entry
        oldest_key = next(iter(_mem_cache))
        del _mem_cache[oldest_key]
    _mem_cache[key] = data

    # Disk cache
    try:
        disk_path = os.path.join(CACHE_DIR, key)
        with open(disk_path, "wb") as f:
            f.write(data)
    except Exception:
        pass


# 1x1 transparent PNG fallback (89 bytes)
TRANSPARENT_PNG = (
    b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01'
    b'\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89'
    b'\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01'
    b'\r\n\xb4\x00\x00\x00\x00IEND\xaeB`\x82'
)


@router.get("/image")
def proxy_image(url: str = Query(..., description="URL of the image to proxy")):
    """
    Proxy external images to bypass CORS restrictions in Flutter Web.
    Includes caching, retry logic, and graceful fallback.
    """
    if not url or not url.startswith("http"):
        return Response(content=TRANSPARENT_PNG, media_type="image/png")

    # Check cache first
    cached = _get_cached(url)
    if cached:
        # Determine content type from URL
        ct = "image/png"
        if url.endswith(".jpg") or url.endswith(".jpeg"):
            ct = "image/jpeg"
        elif url.endswith(".svg"):
            ct = "image/svg+xml"
        elif url.endswith(".webp"):
            ct = "image/webp"
        return Response(
            content=cached,
            media_type=ct,
            headers={
                "Cache-Control": "public, max-age=86400",
                "Access-Control-Allow-Origin": "*",
            },
        )

    # Fetch with retry - set contextual referer per domain
    # Wikipedia blocks requests without proper User-Agent and Referer
    referer = "https://www.google.com/"
    if "soccerwiki.org" in url:
        referer = "https://soccerwiki.org/"
    elif "wikimedia.org" in url or "wikipedia.org" in url:
        referer = "https://en.wikipedia.org/"

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "identity",
        "Referer": referer,
    }

    # Create SSL context that doesn't verify (some CDNs have issues)
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    last_error = None
    for attempt in range(3):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=15, context=ctx) as response:
                content = response.read()
                content_type = response.headers.get("content-type", "image/png")

                # Cache the successful result
                _set_cached(url, content)

                return Response(
                    content=content,
                    media_type=content_type,
                    headers={
                        "Cache-Control": "public, max-age=86400",
                        "Access-Control-Allow-Origin": "*",
                    },
                )
        except urllib.error.HTTPError as e:
            last_error = f"HTTP {e.code}: {e.reason}"
            if e.code == 404:
                break  # No point retrying a 404
        except urllib.error.URLError as e:
            last_error = f"URL Error: {e.reason}"
        except Exception as e:
            last_error = str(e)

        # Wait before retry
        if attempt < 2:
            time.sleep(0.5)

    # All retries failed - return transparent fallback instead of crashing
    print(f"⚠️ Proxy failed for {url}: {last_error}")
    return Response(
        content=TRANSPARENT_PNG,
        media_type="image/png",
        headers={
            "Cache-Control": "no-cache",
            "Access-Control-Allow-Origin": "*",
            "X-Proxy-Error": last_error or "Unknown error",
        },
    )
