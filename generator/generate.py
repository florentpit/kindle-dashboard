#!/usr/bin/env python3
"""Génère l'image du dashboard Kindle (météo Bouliac + actus IA).

Sortie : PNG 8 bits niveaux de gris, à la résolution native du Kindle
11e génération 2024 (1072x1448, 6 pouces, 300 ppi, portrait), utilisable comme écran de veille.

Usage : python3 generate.py [--out DIR]
Variables d'environnement facultatives :
  CHROME   chemin du binaire Chrome/Chromium (détecté automatiquement sinon)
"""
import argparse
import datetime as dt
import email.utils
import html
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import xml.etree.ElementTree as ET
from zoneinfo import ZoneInfo

HERE = os.path.dirname(os.path.abspath(__file__))
TZ = ZoneInfo("Europe/Paris")

# --- Configuration --------------------------------------------------------
CITY = "Bouliac"
LAT, LON = 44.8193, -0.50265
WIDTH, HEIGHT = 1072, 1448          # Kindle 11e gén. (2024), 6", 300 ppi
SCALE = 2                           # mise en page en 536x724 px CSS
CSS_W, CSS_H = WIDTH // SCALE, HEIGHT // SCALE
UPDATE_HOURS = tuple(range(24))    # chaque heure pleine, Europe/Paris


def refresh_schedule(now, days=14):
    """Instants UTC pour le Kindle, calculés avec les règles d'heure de Paris."""
    start = dt.datetime.combine(now.date(), dt.time(), TZ)
    end = dt.datetime.combine(now.date() + dt.timedelta(days=days), dt.time(), TZ)
    # Parcourir les instants UTC évite les doublons au printemps et conserve
    # les deux occurrences de 02h lors du passage à l'heure d'hiver.
    return [t for t in range(int(start.timestamp()), int(end.timestamp()), 3600)
            if dt.datetime.fromtimestamp(t, TZ).hour in UPDATE_HOURS]

TLDR_RSS = "https://tldr.tech/api/rss/ai"
FEEDS = [
    ("TechCrunch", "https://techcrunch.com/category/artificial-intelligence/feed/"),
    ("The Verge", "https://www.theverge.com/rss/ai-artificial-intelligence/index.xml"),
    ("MIT Tech Review", "https://www.technologyreview.com/topic/artificial-intelligence/feed"),
]
UA = "Mozilla/5.0 (KindleDashboard; +https://github.com)"

JOURS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
JOURS_COURTS = ["Lun.", "Mar.", "Mer.", "Jeu.", "Ven.", "Sam.", "Dim."]
MOIS = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet",
        "août", "septembre", "octobre", "novembre", "décembre"]


# --- Réseau ----------------------------------------------------------------
def fetch(url, timeout=25):
    last = None
    for _ in range(3):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return r.read().decode("utf-8", "replace")
        except Exception as e:  # noqa: BLE001
            last = e
    raise RuntimeError(f"échec du téléchargement {url}: {last}")


# --- Météo -------------------------------------------------------------------
WMO = {
    0: ("Ciel dégagé", "clear"), 1: ("Plutôt dégagé", "clear"),
    2: ("Partiellement nuageux", "partly"), 3: ("Couvert", "cloud"),
    45: ("Brouillard", "fog"), 48: ("Brouillard givrant", "fog"),
    51: ("Bruine légère", "drizzle"), 53: ("Bruine", "drizzle"), 55: ("Bruine dense", "drizzle"),
    56: ("Bruine verglaçante", "drizzle"), 57: ("Bruine verglaçante", "drizzle"),
    61: ("Pluie faible", "rain"), 63: ("Pluie", "rain"), 65: ("Forte pluie", "rain"),
    66: ("Pluie verglaçante", "rain"), 67: ("Pluie verglaçante", "rain"),
    71: ("Neige faible", "snow"), 73: ("Neige", "snow"), 75: ("Forte neige", "snow"),
    77: ("Grains de neige", "snow"),
    80: ("Averses", "rain"), 81: ("Averses", "rain"), 82: ("Fortes averses", "rain"),
    85: ("Averses de neige", "snow"), 86: ("Averses de neige", "snow"),
    95: ("Orage", "storm"), 96: ("Orage et grêle", "storm"), 99: ("Orage et grêle", "storm"),
}

_SUN = ('<circle cx="12" cy="12" r="4.2"/>'
        '<path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.3 5.3l1.6 1.6'
        'M17.1 17.1l1.6 1.6M5.3 18.7l1.6-1.6M17.1 6.9l1.6-1.6"/>')
_MOON = '<path d="M19.5 14.5A8 8 0 0 1 9.5 4.5a8 8 0 1 0 10 10z"/>'
_CLOUD = '<path d="M7 19h10.5a4 4 0 0 0 .4-8 6 6 0 0 0-11.6 1.6A3.2 3.2 0 0 0 7 19z"/>'
_CLOUD_HI = '<path d="M7 15.5h10.5a4 4 0 0 0 .4-8 6 6 0 0 0-11.6 1.6A3.2 3.2 0 0 0 7 15.5z"/>'
ICONS = {
    "clear": _SUN,
    "clear-n": _MOON,
    "partly": ('<g transform="translate(-3.2 -3.2) scale(.72)">' + _SUN + '</g>'
               '<path fill="#fff" d="M9 20h9.5a3.6 3.6 0 0 0 .4-7.2 5.4 5.4 0 0 0-10.4 1.4A2.9 2.9 0 0 0 9 20z"/>'),
    "partly-n": ('<g transform="translate(-2.5 -3) scale(.7)">' + _MOON + '</g>'
                 '<path fill="#fff" d="M9 20h9.5a3.6 3.6 0 0 0 .4-7.2 5.4 5.4 0 0 0-10.4 1.4A2.9 2.9 0 0 0 9 20z"/>'),
    "cloud": _CLOUD,
    "fog": _CLOUD_HI + '<path d="M4 18.5h16M6 21.5h12"/>',
    "drizzle": _CLOUD_HI + '<path d="M8.5 18.5v.5M12 19.5v.5M15.5 18.5v.5M10 21.5v.5M14 21.5v.5"/>',
    "rain": _CLOUD_HI + '<path d="M8.5 18l-1 3.5M12.5 18l-1 3.5M16.5 18l-1 3.5"/>',
    "snow": _CLOUD_HI + '<path d="M8 19.5h.01M12 18.5h.01M16 19.5h.01M10 22h.01M14 22h.01" stroke-width="2.6"/>',
    "storm": _CLOUD_HI + '<path d="M12.5 16.5l-2.5 3.5h3l-2 3.5"/>',
}


def icon(code, is_day=True, size=48, stroke=1.6):
    label, key = WMO.get(code, ("—", "cloud"))
    if not is_day and key in ("clear", "partly"):
        key += "-n"
    return (f'<svg class="ico" width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" '
            f'stroke="#000" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round">'
            f'{ICONS[key]}</svg>')


def wind_dir(deg):
    return ["N", "NE", "E", "SE", "S", "SO", "O", "NO"][int((deg % 360) / 45 + 0.5) % 8]


def get_weather():
    params = (
        f"latitude={LAT}&longitude={LON}&timezone=Europe%2FParis&forecast_days=7&wind_speed_unit=kmh"
        "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,"
        "wind_speed_10m,wind_direction_10m,is_day"
        "&hourly=temperature_2m,weather_code,precipitation_probability,is_day"
        "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,"
        "precipitation_sum,sunrise,sunset,uv_index_max"
    )
    return json.loads(fetch("https://api.open-meteo.com/v1/forecast?" + params))


# --- Actus -----------------------------------------------------------------
def clean(text):
    text = html.unescape(re.sub(r"<[^>]+>", " ", text or ""))
    # pas d'emoji : illisibles en niveaux de gris et absents des polices serveur
    text = re.sub("[\U0001F000-\U0001FAFF☀-➿️‍]", "", text)
    return re.sub(r"\s+", " ", text).strip()


def get_tldr(n=2):
    root = ET.fromstring(fetch(TLDR_RSS))
    item = root.find("./channel/item")
    link = item.findtext("link")
    date = email.utils.parsedate_to_datetime(item.findtext("pubDate")).date()
    page = fetch(link)
    stories = []
    for art in re.findall(r"<article.*?</article>", page, re.S):
        h = re.search(r"<h3[^>]*>(.*?)</h3>", art, re.S)
        if not h:
            continue
        title = clean(h.group(1))
        if "(Sponsor)" in title:
            continue
        mins = re.search(r"\((\d+) minute read\)", title)
        title = re.sub(r"\s*\((\d+ minute read|GitHub Repo|Website)\)\s*$", "", title)
        body = clean(re.sub(r"<h3.*?</h3>", "", art, flags=re.S))
        stories.append({"title": title, "summary": body,
                        "read": f"{mins.group(1)} min" if mins else ""})
        if len(stories) >= n:
            break
    return date, stories


def parse_date(s):
    if not s:
        return None
    try:
        return email.utils.parsedate_to_datetime(s)
    except (TypeError, ValueError):
        pass
    try:
        return dt.datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        return None


def get_headlines(n=6):
    atom = "{http://www.w3.org/2005/Atom}"
    items = []
    for source, url in FEEDS:
        try:
            root = ET.fromstring(fetch(url))
        except Exception as e:  # noqa: BLE001
            print(f"[warn] {source}: {e}", file=sys.stderr)
            continue
        entries = root.findall("./channel/item") or root.findall(f"{atom}entry")
        for e in entries[:10]:
            title = clean(e.findtext("title") or e.findtext(f"{atom}title"))
            when = parse_date(e.findtext("pubDate") or e.findtext(f"{atom}published")
                              or e.findtext(f"{atom}updated"))
            if title and when:
                summary = clean(e.findtext("description") or e.findtext(f"{atom}summary")
                                or e.findtext(f"{atom}content") or "")
                items.append({"source": source, "title": title, "when": when,
                              "summary": summary})
    items.sort(key=lambda x: x["when"], reverse=True)
    # max 3 titres par source pour garder de la variété
    out, per = [], {}
    for it in items:
        if per.get(it["source"], 0) < 3:
            out.append(it)
            per[it["source"]] = per.get(it["source"], 0) + 1
        if len(out) >= n:
            break
    return out


def ago(when, now):
    mins = int((now - when).total_seconds() // 60)
    if mins < 60:
        return f"il y a {max(mins, 1)} min"
    if mins < 24 * 60:
        return f"il y a {mins // 60} h"
    return f"il y a {mins // 1440} j"


# --- Rendu -----------------------------------------------------------------
def esc(s):
    return html.escape(s, quote=True)


def build_html(now, w, tldr_date, stories, headlines):
    cur, hourly, daily = w["current"], w["hourly"], w["daily"]
    label, _ = WMO.get(cur["weather_code"], ("—", ""))
    date_txt = f"{JOURS[now.weekday()].capitalize()} {now.day} {MOIS[now.month - 1]}"

    sunrise = daily["sunrise"][0][-5:]
    sunset = daily["sunset"][0][-5:]

    # Quatre créneaux et trois jours : priorité à la lisibilité sur 6 pouces.
    times = [dt.datetime.fromisoformat(t).replace(tzinfo=TZ) for t in hourly["time"]]
    start = next(i for i, t in enumerate(times) if t > now)
    hours_html = ""
    for i in range(start, min(start + 12, len(times)), 3):
        pp = hourly["precipitation_probability"][i]
        hours_html += (
            f'<div class="h"><div class="hh">{times[i].hour:02d}h</div>'
            f'{icon(hourly["weather_code"][i], hourly["is_day"][i], 32, 1.8)}'
            f'<div class="ht">{round(hourly["temperature_2m"][i])}°</div>'
            f'<div class="hp">{pp if pp is not None else 0}&#8239;%</div></div>'
        )

    days_html = ""
    for i in range(1, 4):
        d = dt.date.fromisoformat(daily["time"][i])
        lo, hi = daily["temperature_2m_min"][i], daily["temperature_2m_max"][i]
        days_html += (
            f'<div class="d"><div class="day-top"><div class="dn">{JOURS_COURTS[d.weekday()]} {d.day}</div>'
            f'{icon(daily["weather_code"][i], True, 28, 1.8)}</div>'
            f'<div class="dt"><b>{round(hi)}°</b> <span>{round(lo)}°</span></div>'
            f'<div class="dp">{daily["precipitation_probability_max"][i] or 0}&#8239;% pluie</div></div>'
        )

    display_stories = [dict(s, source="TLDR AI") for s in stories[:2]]
    for it in headlines:
        if len(display_stories) == 3:
            break
        if any(s["title"].casefold() == it["title"].casefold() for s in display_stories):
            continue
        display_stories.append(it)
    stories_html = ""
    for s in display_stories:
        stories_html += (
            f'<article class="st"><div class="story-top">'
            f'<div class="stt">{esc(s["title"])}</div>'
            f'<span class="source">{esc(s["source"])}</span></div>'
            f'<div class="sts">{esc(s.get("summary", ""))}</div></article>'
        )
    fonts = os.path.join(HERE, "fonts")

    return f"""<!doctype html><html lang="fr"><head><meta charset="utf-8">
<style>
@font-face {{ font-family: Inter; src: url("file://{fonts}/Inter.ttf"); font-weight: 100 900; }}
@font-face {{ font-family: News; src: url("file://{fonts}/Newsreader.ttf"); font-weight: 200 800; }}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
html, body {{ width: {CSS_W}px; height: {CSS_H}px; background: #fff; color: #000; overflow: hidden; }}
body {{ font-family: Inter, sans-serif; padding: 20px 22px 10px; display: flex; flex-direction: column;
       -webkit-font-smoothing: antialiased; }}
.ico {{ display: block; }}
header {{ display: flex; justify-content: space-between; align-items: flex-end;
          padding-bottom: 7px; border-bottom: 3px solid #000; }}
.kick {{ font-size: 14px; font-weight: 700; letter-spacing: .12em; text-transform: uppercase; }}
h1 {{ font-family: News; font-weight: 600; font-size: 33px; line-height: 1; margin-top: 4px; letter-spacing: -.01em; }}
.ed {{ text-align: right; font-size: 14px; color: #222; line-height: 1.3; flex-shrink: 0; }}
.ed b {{ color: #000; font-weight: 700; }}

.now {{ display: flex; gap: 14px; align-items: center; padding: 10px 0 6px; }}
.temp {{ font-family: News; font-size: 85px; font-weight: 500; line-height: .85; letter-spacing: -.04em; }}
.cond {{ font-family: News; font-size: 26px; font-weight: 600; line-height: 1.05; }}
.sub {{ font-size: 16px; color: #111; margin-top: 5px; line-height: 1.25; }}
.facts {{ display: flex; justify-content: space-between; gap: 12px; font-size: 15px; padding: 5px 0 9px; color: #111; }}
.facts b {{ font-weight: 700; color: #000; }}

.hours {{ display: grid; grid-template-columns: repeat(4, 1fr); border-top: 2px solid #000;
          border-bottom: 2px solid #000; }}
.h {{ display: grid; grid-template-columns: 1fr auto; align-items: center; gap: 1px 5px; padding: 6px 9px;
      border-left: 1px solid #999; }}
.h:first-child {{ border-left: 0; }}
.h .ico {{ grid-column: 2; grid-row: 1 / span 2; }}
.hh {{ font-size: 16px; font-weight: 600; color: #222; }}
.ht {{ font-size: 23px; font-weight: 700; }}
.hp {{ display: none; }}

.days {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; padding: 8px 0 10px; }}
.d {{ display: flex; flex-direction: column; gap: 2px; }}
.day-top {{ display: flex; align-items: center; justify-content: space-between; }}
.dn {{ font-size: 16px; font-weight: 700; }}
.dt {{ font-size: 22px; }} .dt b {{ font-weight: 700; }} .dt span {{ color: #333; }}
.dp {{ font-size: 15px; color: #222; }}

.sec {{ border-top: 2px solid #000; padding: 7px 0 1px; }}
.sec h2 {{ font-family: Inter; font-size: 15px; font-weight: 750; letter-spacing: .07em;
           text-transform: uppercase; }}

.st {{ padding: 8px 0;
       border-bottom: 1px solid #999; }}
.st:last-child {{ border-bottom: 0; }}
.story-top {{ display: flex; justify-content: space-between; align-items: baseline; gap: 10px; }}
.source {{ font-size: 12px; font-weight: 650; color: #333; white-space: nowrap; }}
.stt {{ font-family: News; font-size: 23px; font-weight: 650; line-height: 1.12;
        display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }}
.sts {{ font-size: 18px; line-height: 1.25; color: #111; margin-top: 3px;
        display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }}
</style></head><body>
<header>
  <div><div class="kick">{CITY} · Gironde</div><h1>{date_txt}</h1></div>
  <div class="ed">Mis à jour<br><b>{now:%H:%M}</b></div>
</header>

<section class="now">
  {icon(cur["weather_code"], cur["is_day"], 74, 1.4)}
  <div class="temp">{round(cur["temperature_2m"])}°</div>
  <div>
    <div class="cond">{esc(label)}</div>
    <div class="sub">Ressenti {round(cur["apparent_temperature"])}° · Vent {round(cur["wind_speed_10m"])}&#8239;km/h {wind_dir(cur["wind_direction_10m"])}<br>Humidité {cur["relative_humidity_2m"]}&#8239;% · UV {round(daily["uv_index_max"][0] or 0)}</div>
  </div>
</section>
<div class="facts">
  <span><b>{round(daily["temperature_2m_max"][0])}°</b> max · <b>{round(daily["temperature_2m_min"][0])}°</b> min</span>
  <span>Pluie <b>{daily["precipitation_probability_max"][0] or 0}&#8239;%</b> · {str(round(daily["precipitation_sum"][0], 1)).replace(".", ",")}&#8239;mm</span>
  <span>Soleil {sunrise} – {sunset}</span>
</div>
<section class="hours">{hours_html}</section>
<section class="days">{days_html}</section>

<div class="sec"><h2>Actualité IA</h2></div>
<section>{stories_html}</section>
<script>
// Préserve les trois actualités et les grandes polices, même si les titres sont longs.
function fitPage() {{
  var limit = {CSS_H} - 10;
  function over() {{
    var els = document.querySelectorAll(".st");
    return els.length && els[els.length - 1].getBoundingClientRect().bottom > limit;
  }}
  var pools = [".sts", ".stt"];
  for (var p = 0; p < pools.length && over(); p++) {{
    document.querySelectorAll(pools[p]).forEach(function (el) {{ el.style.webkitLineClamp = "1"; }});
  }}
  document.documentElement.dataset.layoutOverflow = over() ? "1" : "0";
}}
document.fonts.ready.then(fitPage);
window.addEventListener("load", fitPage);
</script></body></html>"""


def find_chrome():
    cands = [os.environ.get("CHROME"),
             "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
             shutil.which("google-chrome"), shutil.which("google-chrome-stable"),
             shutil.which("chromium"), shutil.which("chromium-browser")]
    for c in cands:
        if c and os.path.exists(c):
            return c
    sys.exit("Chrome/Chromium introuvable (définissez CHROME)")


def render(html_path, png_path):
    with tempfile.TemporaryDirectory() as profile:
        subprocess.run([
            find_chrome(), "--headless=new", "--disable-gpu", "--no-sandbox", "--hide-scrollbars",
            "--allow-file-access-from-files", f"--user-data-dir={profile}",
            f"--window-size={WIDTH // SCALE},{HEIGHT // SCALE}",
            f"--force-device-scale-factor={SCALE}", "--virtual-time-budget=4000",
            f"--screenshot={png_path}", "file://" + html_path,
        ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=120)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "site"))
    args = ap.parse_args()
    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)

    now = dt.datetime.now(TZ)
    weather = get_weather()
    try:
        tldr_date, stories = get_tldr()
    except Exception as e:  # noqa: BLE001
        print(f"[warn] TLDR: {e}", file=sys.stderr)
        tldr_date, stories = now.date(), []
    headlines = get_headlines(3 if stories else 8)

    page = build_html(now, weather, tldr_date, stories, headlines)
    html_path = os.path.join(out, "dashboard.html")
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(page)

    raw = os.path.join(out, "raw.png")
    render(html_path, raw)

    from PIL import Image
    img = Image.open(raw).convert("L")
    if img.size != (WIDTH, HEIGHT):
        img = img.resize((WIDTH, HEIGHT), Image.LANCZOS)
    img.save(os.path.join(out, "dashboard.png"), optimize=True)
    os.remove(raw)
    with open(os.path.join(out, "version.txt"), "w") as f:
        f.write(now.isoformat(timespec="seconds") + "\n")
    # Formats simples lisibles par BusyBox, sans Python ni base de fuseaux sur le Kindle.
    with open(os.path.join(out, "schedule.txt"), "w") as f:
        f.write("".join(f"{t}\n" for t in refresh_schedule(now)))
    with open(os.path.join(out, "dashboard.png"), "rb") as f:
        digest = hashlib.sha256(f.read()).hexdigest()
    with open(os.path.join(out, "dashboard.sha256"), "w") as f:
        f.write(f"{digest}  dashboard.png\n")
    print(f"OK -> {os.path.join(out, 'dashboard.png')}")


if __name__ == "__main__":
    main()
