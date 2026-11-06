#!/usr/bin/env python3
"""
walls_api.py — navigateur de fonds d'écran en ligne pour le Studio.

Interroge plusieurs API (Wallhaven + boorus anime, MotionBGs pour les fonds
animés) et renvoie une liste normalisée de miniatures ; télécharge le plein
format dans wallpapers/[live/]sfw|nsfw/<Source>/ du rice (live = vidéo,
sfw/nsfw selon la note du site) pour que la bibliothèque locale le voie.

Sortie : toujours du JSON sur stdout.

Commandes
  search <source> <page> <rating> <image|live> [requête...]
         -> {items:[{id,thumb,full,res,w,h,nsfw,video}], more, source}
  dl     <source> <id> <url> [sfw|nsfw]  -> {ok, path} | {error}

Filtrage : SFW verrouillé sur chaque source (purity/rating).
La clé Gelbooru est lue dans ~/.config/catalyst/secrets.env (hors dépôt).
"""
import json
import os
import re
import sys
import urllib.parse
import urllib.request

HOME = os.path.expanduser("~")
WALLDIR = os.path.join(HOME, ".config", "quickshell", "catalyst", "wallpapers")
SAFE_RATINGS = ("sfw", "s", "safe", "general", "g")
UA = "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"
SECRETS_ENV = os.path.join(HOME, ".config", "catalyst", "secrets.env")

LIMIT = 24

# id -> (libellé, dossier, anime ?)
SOURCES = {
    "wallhaven": ("Wallhaven", "Wallhaven", False),
    "konachan":  ("Konachan",  "Konachan",  True),
    "yandere":   ("Yande.re",  "Yandere",   True),
    "gelbooru":  ("Gelbooru",  "Gelbooru",  True),
    "safebooru": ("Safebooru", "Safebooru", True),
    "motionbgs": ("MotionBGs", "MotionBGs", True),   # vidéos uniquement, site SFW
}
VIDEO_RE = r"\.(mp4|webm)$"
MOTIONBGS = "https://motionbgs.com"


def die(msg):
    print(json.dumps({"error": msg}))
    sys.exit(0)


def gelbooru_auth():
    """Chaîne d'auth Gelbooru : variables d'environnement, sinon ~/.config/catalyst/secrets.env."""
    key = os.environ.get("GELBOORU_API_KEY", "")
    uid = os.environ.get("GELBOORU_USER_ID", "")
    if not (key and uid):
        try:
            with open(SECRETS_ENV, "r", encoding="utf-8") as f:
                txt = f.read()
            mk = re.search(r'^GELBOORU_API_KEY="?([^"\n]*)"?', txt, re.M)
            mu = re.search(r'^GELBOORU_USER_ID="?([^"\n]*)"?', txt, re.M)
            key = key or (mk.group(1) if mk else "")
            uid = uid or (mu.group(1) if mu else "")
        except OSError:
            pass
    if key and uid:
        return "&api_key=%s&user_id=%s" % (key, uid)
    return ""  # Gelbooru fonctionne sans clé (throttle plus agressif)


def get(url, headers=None, timeout=20):
    h = {"User-Agent": UA, "Accept": "application/json"}
    if headers:
        h.update(headers)
    req = urllib.request.Request(url, headers=h)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def get_json(url, headers=None):
    return json.loads(get(url, headers).decode("utf-8", "replace"))


def q_enc(query):
    return urllib.parse.quote(query.strip())


# ----- sources -----

def s_wallhaven(page, query, rating):
    q = query.strip()
    cats = "111"
    if q.startswith("anime:"):
        cats, q = "010", q[6:].strip()
    elif q.startswith("photo:") or q.startswith("general:"):
        cats, q = "101", q.split(":", 1)[1].strip()
    # purity : sans clé API, le vrai NSFW (001) est indisponible -> sketchy (010)
    purity = {"safe": "100", "nsfw": "010", "all": "110"}.get(rating, "100")
    sort = "toplist" if not q else "relevance"
    url = ("https://wallhaven.cc/api/v1/search?q=%s&categories=%s&purity=%s"
           "&atleast=1920x1080&sorting=%s&page=%d"
           % (q_enc(q), cats, purity, sort, page))
    d = get_json(url)
    out = []
    for x in d.get("data", []):
        if x.get("file_type", "").startswith("video"):
            continue
        out.append({
            "id": x["id"], "thumb": x["thumbs"]["small"], "full": x["path"],
            "res": x.get("resolution", ""),
            "nsfw": x.get("purity", "sfw") not in SAFE_RATINGS,
            "w": x.get("dimension_x", 0), "h": x.get("dimension_y", 0),
        })
    meta = d.get("meta", {})
    more = meta.get("current_page", page) < meta.get("last_page", page)
    return out, more


def s_moebooru(host, page, query, rating):
    safe_tag = {"safe": "rating:safe", "nsfw": "-rating:safe", "all": ""}.get(rating, "rating:safe")
    tags = (safe_tag + " " + query.strip()).strip()
    url = ("https://%s/post.json?tags=%s&page=%d&limit=%d"
           % (host, q_enc(tags), page, LIMIT))
    d = get_json(url)
    out = []
    for x in d:
        full = x.get("file_url") or ""
        prev = x.get("preview_url") or full
        if not full or not re.search(r"\.(jpe?g|png|webp)$", full, re.I):
            continue
        out.append({
            "id": str(x.get("id")), "thumb": prev, "full": full,
            "res": "%sx%s" % (x.get("width", "?"), x.get("height", "?")),
            "nsfw": str(x.get("rating", "s")).lower() not in SAFE_RATINGS,
            "w": x.get("width", 0), "h": x.get("height", 0),
        })
    return out, len(d) >= LIMIT


def s_motionbgs(page, query, rating):
    """MotionBGs : pas d'API, on lit les pages de résultats (vidéos SFW)."""
    if rating == "nsfw":
        die("MotionBGs ne propose que du SFW — passe sur Gelbooru pour le NSFW")
    q = query.strip()
    if q:
        url = "%s/search?q=%s&page=%d" % (MOTIONBGS, urllib.parse.quote_plus(q), page)
    else:
        url = MOTIONBGS + ("/" if page == 1 else "/%d/" % page)
    html = get(url, {"Accept": "text/html"}).decode("utf-8", "replace")
    out = []
    # <a title="… live wallpaper" href=/slug> … src=/i/c/364x205/media/<id>/<fichier>.jpg … <span class=frm> 4K </span>
    for m in re.finditer(r'<a title="([^"]*?) live wallpaper" href=/([\w-]+)>(.*?)</a>', html, re.S):
        title, body = m.group(1), m.group(3)
        img = re.search(r"src=(/i/c/[^ >]+?/media/(\d+)/[^ >]+?\.jpg)", body)
        if not img:
            continue
        frm = re.search(r"class=frm>\s*([^<]+?)\s*<", body)
        out.append({
            "id": img.group(2), "thumb": MOTIONBGS + img.group(1),
            "full": "%s/dl/hd/%s/" % (MOTIONBGS, img.group(2)),
            "res": (frm.group(1) if frm else "HD") + " · " + title,
            "w": 1920, "h": 1080, "nsfw": False, "video": True,
        })
    return out, len(out) >= 24


def s_booru_dapi(base, page, query, rating, live=False):
    """Gelbooru / Safebooru (API 'dapi', pid 0-based)."""
    if base == "gelbooru.com":
        extra_tags = {"safe": "rating:general", "nsfw": "-rating:general",
                      "all": ""}.get(rating, "rating:general")
    else:
        extra_tags = ""  # Safebooru : site SFW uniquement
    if live:  # vidéos en paysage seulement (fond d'écran animé)
        extra_tags += " video width:>=1280"
    tags = (extra_tags + " " + query.strip()).strip()
    url = ("https://%s/index.php?page=dapi&s=post&q=index&json=1"
           "&limit=%d&pid=%d&tags=%s" % (base, LIMIT, page - 1, q_enc(tags)))
    if base == "gelbooru.com":
        url += gelbooru_auth()
    d = get_json(url)
    posts = d if isinstance(d, list) else d.get("post", [])
    out = []
    for x in posts:
        full = x.get("file_url") or ""
        if not full or not re.search(VIDEO_RE if live else r"\.(jpe?g|png|webp)$", full, re.I):
            continue
        out.append({
            "id": str(x.get("id")), "thumb": x.get("preview_url") or full,
            "full": full,
            "res": "%sx%s" % (x.get("width", "?"), x.get("height", "?")),
            "nsfw": str(x.get("rating", "general")).lower() not in SAFE_RATINGS,
            "video": live,
            "w": x.get("width", 0), "h": x.get("height", 0),
        })
    return out, len(posts) >= LIMIT


def cmd_search(source, page, rating, query, live=False):
    try:
        if live and source not in ("motionbgs", "gelbooru"):
            die("pas de fonds animés sur cette source")
        if source == "motionbgs":
            items, more = s_motionbgs(page, query, rating)
        elif source == "wallhaven":
            items, more = s_wallhaven(page, query, rating)
        elif source == "konachan":
            items, more = s_moebooru("konachan.com", page, query, rating)
        elif source == "yandere":
            items, more = s_moebooru("yande.re", page, query, rating)
        elif source == "gelbooru":
            items, more = s_booru_dapi("gelbooru.com", page, query, rating, live)
        elif source == "safebooru":
            items, more = s_booru_dapi("safebooru.org", page, query, rating)
        else:
            die("source inconnue : " + source)
    except urllib.error.HTTPError as e:
        die("HTTP %s sur %s" % (e.code, source))
    except Exception as e:  # noqa: BLE001
        die("%s : %s" % (source, e))
    print(json.dumps({"items": items, "more": bool(more), "source": source}))


def cmd_dl(source, sid, url, nsfw=False):
    if source not in SOURCES:
        die("source inconnue : " + source)
    ext = os.path.splitext(urllib.parse.urlparse(url).path)[1].lower()
    video = source == "motionbgs" or ext in (".mp4", ".webm")
    if source == "motionbgs":
        ext = ".mp4"  # /dl/hd/<id>/ : pas d'extension dans l'URL
    elif ext not in (".jpg", ".jpeg", ".png", ".webp", ".mp4", ".webm"):
        ext = ".jpg"
    folder = os.path.join(WALLDIR, *(["live"] if video else []),
                          "nsfw" if nsfw else "sfw", SOURCES[source][1])
    os.makedirs(folder, exist_ok=True)
    safe_id = re.sub(r"[^A-Za-z0-9_.-]", "_", str(sid))
    path = os.path.join(folder, "%s_%s%s" % (source, safe_id, ext))
    try:
        data = get(url, {"Accept": "*/*"}, timeout=180 if video else 20)
        if len(data) < 1024:
            die("fichier trop petit (téléchargement incomplet)")
        with open(path, "wb") as f:
            f.write(data)
    except Exception as e:  # noqa: BLE001
        die("téléchargement : %s" % e)
    print(json.dumps({"ok": True, "path": path}))


def main():
    a = sys.argv[1:]
    if not a:
        die("usage: search|dl …")
    if a[0] == "search":
        if len(a) < 5:
            die("usage: search <source> <page> <rating> <image|live> [requête]")
        rating = a[3] if a[3] in ("safe", "nsfw", "all") else "safe"
        cmd_search(a[1], int(a[2]), rating, " ".join(a[5:]), a[4] == "live")
    elif a[0] == "dl":
        if len(a) < 4:
            die("usage: dl <source> <id> <url> [nsfw]")
        cmd_dl(a[1], a[2], a[3], len(a) > 4 and a[4] == "nsfw")
    else:
        die("commande inconnue : " + a[0])


if __name__ == "__main__":
    main()
