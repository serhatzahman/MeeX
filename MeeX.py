#!/usr/bin/env python3
"""
MeeX Bridge Server (Comprehensive Edition)
------------------------------------------
Nokia N9 (MeeGo 1.2 Harmattan) için tam donanımlı X (Twitter) köprü sunucusu.

Özellikler:
- Zaman tüneli (Home Timeline)
- Kullanıcı profili ve kullanıcının tweet'leri
- Tweet detay sayfası ve yanıt zinciri (Thread / Conversation)
- Arama (Search) ve Gündem Konuları (Trends)
- Yer İmleri (Bookmarks listeleme / ekleme / silme)
- Beğeni (Like / Unlike) ve Retweet (Retweet / Unretweet)
- Resimli tweet gönderme (Media upload)
- Sağlam görsel proxy motoru (N9 SSL hatalarını önler)
- Nokia N9 için emoji ve karakter temizleyici
- X-Client-Transaction dinamik Webpack yaması
"""

import os
import sys
import json
import logging
import asyncio
import threading
import re
import ssl
import base64
import urllib.parse
import urllib.request
from flask import Flask, request, jsonify, Response, send_from_directory
from flask_cors import CORS

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

_ssl_context = ssl.create_default_context()
_ssl_context.check_hostname = False
_ssl_context.verify_mode = ssl.CERT_NONE

# ==============================================================
# TWIKIT MONKEY PATCH (X ondemand.s.js Webpack regex yaması)
# ==============================================================
try:
    _tx_mod = __import__('twikit.x_client_transaction.transaction', fromlist=['ClientTransaction'])
    _tx_mod.ON_DEMAND_FILE_REGEX = re.compile(r""",(\d+):["']ondemand\.s["']""", flags=(re.VERBOSE | re.MULTILINE))
    _tx_mod.ON_DEMAND_HASH_PATTERN = r',{}:"([0-9a-f]+)"'

    async def _patched_get_indices(self, home_page_response, session, headers):
        key_byte_indices = []
        response = self.validate_response(home_page_response) or self.home_page_response
        resp_str = str(response)

        match = _tx_mod.ON_DEMAND_FILE_REGEX.search(resp_str)
        if match:
            on_demand_file_index = match.group(1)
            regex = re.compile(_tx_mod.ON_DEMAND_HASH_PATTERN.format(on_demand_file_index))
            filename = regex.search(resp_str).group(1)
        else:
            fallback_match = re.search(r'["\']ondemand\.s["\']:\s*["\']([\w]*)["\']', resp_str)
            if fallback_match:
                filename = fallback_match.group(1)
            else:
                raise Exception("Sayfa kaynağından ondemand.s dosyası bulunamadı")

        on_demand_file_url = f"https://abs.twimg.com/responsive-web/client-web/ondemand.s.{filename}a.js"
        on_demand_file_response = await session.request(method="GET", url=on_demand_file_url, headers=headers)
        js_text = str(on_demand_file_response.text)

        key_byte_indices_match = _tx_mod.INDICES_REGEX.finditer(js_text)
        for item in key_byte_indices_match:
            val = item.group(2) if len(item.groups()) >= 2 and item.group(2) is not None else item.group(1)
            key_byte_indices.append(val)

        if not key_byte_indices:
            alt_match = re.finditer(r"\[(\d+)\],\s*16", js_text)
            for item in alt_match:
                key_byte_indices.append(item.group(1))

        if not key_byte_indices:
            raise Exception("Couldn't get KEY_BYTE indices")

        key_byte_indices = list(map(int, key_byte_indices))
        return key_byte_indices[0], key_byte_indices[1:]

    _tx_mod.ClientTransaction.get_indices = _patched_get_indices
    logging.info("✓ X-Client-Transaction yaması devrede.")
except Exception as e:
    logging.warning(f"Twikit yama uyarısı: {e}")

from twikit import Client

# ==============================================================
# HESAP VE ÇEREZ AYARLARI
# ==============================================================
AUTH_TOKEN = os.environ.get("X_AUTH_TOKEN", "")
CT0 = os.environ.get("X_CT0", "")
DEFAULT_USERNAME = os.environ.get("X_USERNAME", "")

app = Flask(__name__)
CORS(app)

client = Client(language='tr-TR')

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
COOKIES_FILE = os.path.join(BASE_DIR, 'cookies.json')

_loop = asyncio.new_event_loop()
_thread = threading.Thread(target=_loop.run_forever, daemon=True)
_thread.start()

def run_async(coro, timeout=35):
    future = asyncio.run_coroutine_threadsafe(coro, _loop)
    return future.result(timeout=timeout)

def load_session():
    global DEFAULT_USERNAME
    if AUTH_TOKEN and CT0:
        client.set_cookies({'auth_token': AUTH_TOKEN, 'ct0': CT0})
        logging.info("✓ auth_token & ct0 çerezleriyle oturum açıldı.")
        return True

    if os.path.exists(COOKIES_FILE):
        try:
            with open(COOKIES_FILE, 'r', encoding='utf-8') as f:
                c_data = json.load(f)
                if isinstance(c_data, dict) and 'auth_token' in c_data and 'ct0' in c_data:
                    client.set_cookies({'auth_token': c_data['auth_token'], 'ct0': c_data['ct0']})
                    if not DEFAULT_USERNAME and 'username' in c_data:
                        DEFAULT_USERNAME = c_data['username']
                    logging.info("✓ cookies.json içindeki çerezlerle oturum açıldı.")
                    return True
            client.load_cookies(COOKIES_FILE)
            logging.info("✓ Mevcut cookies.json dosyasından oturum yüklendi.")
            return True
        except Exception as e:
            logging.warning(f"Kayıtlı çerezler okunamadı: {e}")

    logging.warning("⚠️ Çerez bulunamadı!")
    return False

# ==============================================================
# NOKIA N9 İÇİN EMOJİ VE KARAKTER DÜZENLEYİCİ
# ==============================================================
COMMON_EMOJI_MAP = {
    "❤️": "♥", "💖": "♥", "💕": "♥", "🖤": "♥", "🤍": "♥", "💙": "♥", "💚": "♥", "💛": "♥", "💜": "♥",
    "👍": "[+1]", "👎": "[-1]", "🔥": "[Alev]", "🚀": "[Roket]", "💯": "[100]",
    "✨": "*", "⭐": "★", "⚡": "⚡", "🎉": "[Kutlama]", "🎊": "[Kutlama]",
    "😂": ":D", "🤣": ":D", "😊": ":)", "🙂": ":)", "😍": ":*", "🥰": ":*",
    "😭": ":'(", "😢": ":(", "🤔": "[?]", "👀": "[Bakış]", "👏": "[Alkış]",
    "🙏": "[Dua]", "💪": "[Güç]", "🇹🇷": "[TR]", "✅": "✓", "❌": "X",
    "☕": "[Kahve]", "🍕": "[Pizza]", "⚽": "[Futbol]", "📸": "[Foto]"
}

def clean_text_for_n9(text):
    if not text:
        return ""
    for emoji_char, replacement in COMMON_EMOJI_MAP.items():
        text = text.replace(emoji_char, replacement)
    
    safe_chars = [ch for ch in text if ord(ch) <= 0xFFFF]
    return "".join(safe_chars)

# ==============================================================
# GÜVENİLİR RESİM PROXY'Sİ (N9 SSL Hatasını Kesin Çözer)
# ==============================================================
@app.route('/api/proxy_image', methods=['GET'])
def proxy_image():
    raw_url = request.args.get('url', '').strip()
    if not raw_url:
        return "URL eksik", 400

    img_url = urllib.parse.unquote(urllib.parse.unquote(raw_url)).strip().strip('"').strip("'")
    
    if not img_url.startswith('http://') and not img_url.startswith('https://'):
        if img_url.startswith('https:/') and not img_url.startswith('https://'):
            img_url = 'https://' + img_url[7:]
        elif img_url.startswith('http:/') and not img_url.startswith('http://'):
            img_url = 'http://' + img_url[6:]
        else:
            return f"Geçersiz URL: {img_url}", 400

    try:
        req = urllib.request.Request(img_url, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Referer': 'https://x.com/',
            'Accept': '*/*'
        })
        with urllib.request.urlopen(req, context=_ssl_context, timeout=12) as r:
            img_data = r.read()
            mime = r.headers.get('Content-Type', 'image/jpeg')
            return Response(img_data, mimetype=mime)
    except Exception as e_urllib:
        logging.error(f"Görsel indirme hatası ({img_url}): {e_urllib}")
        return str(e_urllib), 500

# ==============================================================
# API YARDIMCI VE BİÇİMLENDİRME FONKSİYONLARI
# ==============================================================
def format_tweet(t, host):
    user_obj = getattr(t, 'user', None)
    user_name = getattr(user_obj, 'name', 'Kullanıcı') if user_obj else 'Kullanıcı'
    screen_name = "@" + getattr(user_obj, 'screen_name', 'anon') if user_obj else '@anon'

    avatar_url = ""
    if user_obj:
        avatar_url = getattr(user_obj, 'profile_image_url_https', '') or getattr(user_obj, 'profile_image_url', '')
        if avatar_url and "_normal." in avatar_url:
            avatar_url = avatar_url.replace("_normal.", "_bigger.")

    media_url = ""
    media_list = getattr(t, 'media', [])
    if media_list and len(media_list) > 0:
        first_media = media_list[0]
        media_url = getattr(first_media, 'media_url_https', '') or getattr(first_media, 'media_url', '')

    if avatar_url:
        avatar_url = f"http://{host}/api/proxy_image?url=" + urllib.parse.quote(avatar_url, safe='')
    if media_url:
        media_url = f"http://{host}/api/proxy_image?url=" + urllib.parse.quote(media_url, safe='')

    likes = getattr(t, 'favorite_count', 0) or getattr(t, 'likes', 0) or 0
    retweets = getattr(t, 'retweet_count', 0) or getattr(t, 'retweets', 0) or 0
    favorited = bool(getattr(t, 'favorited', False) or (hasattr(t, 'legacy') and isinstance(t.legacy, dict) and t.legacy.get('favorited', False)))
    retweeted = bool(getattr(t, 'retweeted', False) or (hasattr(t, 'legacy') and isinstance(t.legacy, dict) and t.legacy.get('retweeted', False)))
    bookmarked = bool(getattr(t, 'bookmarked', False) or (hasattr(t, 'legacy') and isinstance(t.legacy, dict) and t.legacy.get('bookmarked', False)))

    created_at_raw = str(getattr(t, 'created_at', ''))
    time_display = created_at_raw[:16] if len(created_at_raw) >= 16 else created_at_raw

    return {
        "id": str(t.id),
        "user": clean_text_for_n9(user_name),
        "screen_name": screen_name,
        "avatar": avatar_url,
        "text": clean_text_for_n9(t.text),
        "media": media_url,
        "likes": int(likes),
        "retweets": int(retweets),
        "favorited": favorited,
        "retweeted": retweeted,
        "bookmarked": bookmarked,
        "created_at": time_display
    }

# ==============================================================
# API UÇ NOKTALARI
# ==============================================================
@app.route('/files/<path:filename>', methods=['GET'])
def serve_file(filename):
    return send_from_directory(BASE_DIR, filename)

@app.route('/install', methods=['GET'])
def serve_installer():
    host = request.host
    script = f"""#!/bin/sh
echo "=========================================="
echo "    MeeX Nokia N9 Otomatik Kurulumu       "
echo "=========================================="
mkdir -p /opt/MeeX /usr/share/applications /usr/share/icons/hicolor/80x80/apps

echo "[1/4] main.qml indiriliyor..."
wget -q -O /opt/MeeX/main.qml http://{host}/files/main.qml

echo "[2/4] run.py indiriliyor..."
wget -q -O /opt/MeeX/run.py http://{host}/files/run.py
chmod +x /opt/MeeX/run.py

echo "[3/4] meex.png indiriliyor..."
wget -q -O /usr/share/icons/hicolor/80x80/apps/meex.png http://{host}/files/meex.png

echo "[4/4] meex.desktop indiriliyor..."
wget -q -O /usr/share/applications/meex.desktop http://{host}/files/meex.desktop

echo ""
echo "✓ Kurulum basariyla tamamlandi!"
echo "MeeX simgesi Nokia N9 uygulama menunuze eklendi."
echo "Menuden simgeye dokunarak veya 'python /opt/MeeX/run.py' ile calistirabilirsiniz."
"""
    return Response(script, mimetype='text/plain')

@app.route('/api/status', methods=['GET'])
def get_status():
    return jsonify({
        "status": "online",
        "service": "MeeX Comprehensive Edition",
        "user": DEFAULT_USERNAME,
        "has_cookies": bool(AUTH_TOKEN and CT0) or os.path.exists(COOKIES_FILE)
    })

# --- 1. Zaman Tüneli (Timeline) ---
async def _async_get_timeline(count, host):
    tweets = await client.get_timeline(count=count)
    return [format_tweet(t, host) for t in tweets]

@app.route('/api/timeline', methods=['GET'])
def get_timeline():
    count = request.args.get('count', default=20, type=int)
    host = request.host
    try:
        feed = run_async(_async_get_timeline(count, host))
        logging.info(f"Akış çekildi: {len(feed)} tweet N9'a gönderildi.")
        return jsonify({"status": "success", "data": feed})
    except Exception as e:
        logging.error(f"Timeline hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# --- 2. Kullanıcı Profili ---
async def _async_get_profile(screen_name, host):
    target = screen_name if screen_name else DEFAULT_USERNAME
    target = target.replace("@", "").strip()
    user = await client.get_user_by_screen_name(target)

    avatar = getattr(user, 'profile_image_url_https', '') or getattr(user, 'profile_image_url', '')
    if avatar and "_normal." in avatar:
        avatar = avatar.replace("_normal.", "_400x400.")

    banner = getattr(user, 'profile_banner_url', '')
    if banner:
        banner = banner + "/600x200"

    if avatar:
        avatar = f"http://{host}/api/proxy_image?url=" + urllib.parse.quote(avatar, safe='')
    if banner:
        banner = f"http://{host}/api/proxy_image?url=" + urllib.parse.quote(banner, safe='')

    return {
        "name": clean_text_for_n9(user.name),
        "screen_name": "@" + user.screen_name,
        "description": clean_text_for_n9(getattr(user, 'description', '') or ''),
        "followers_count": getattr(user, 'followers_count', 0) or 0,
        "following_count": getattr(user, 'following_count', 0) or 0,
        "statuses_count": getattr(user, 'statuses_count', 0) or 0,
        "location": clean_text_for_n9(getattr(user, 'location', '') or ''),
        "created_at": str(getattr(user, 'created_at', ''))[:10],
        "avatar": avatar,
        "banner": banner
    }

@app.route('/api/profile', methods=['GET'])
def get_profile():
    screen_name = request.args.get('user', '')
    host = request.host
    try:
        prof = run_async(_async_get_profile(screen_name, host))
        return jsonify({"status": "success", "data": prof})
    except Exception as e:
        logging.error(f"Profil hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# --- 3. Kullanıcının Kendi Tweetleri ---
async def _async_get_user_tweets(screen_name, count, host):
    target = screen_name if screen_name else DEFAULT_USERNAME
    target = target.replace("@", "").strip()
    user = await client.get_user_by_screen_name(target)
    tweets = await user.get_tweets('Tweets', count=count)
    return [format_tweet(t, host) for t in tweets]

@app.route('/api/user_tweets', methods=['GET'])
def get_user_tweets():
    screen_name = request.args.get('user', '')
    count = request.args.get('count', default=20, type=int)
    host = request.host
    try:
        feed = run_async(_async_get_user_tweets(screen_name, count, host))
        logging.info(f"Kullanıcı tweetleri çekildi: {len(feed)} adet.")
        return jsonify({"status": "success", "data": feed})
    except Exception as e:
        logging.error(f"Kullanıcı tweetleri hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# --- 4. Tweet Detay Sayfası ve Yanıtlar (Thread) ---
async def _async_get_tweet_detail(tweet_id, host):
    tweet = await client.get_tweet_by_id(tweet_id)
    main_tweet = format_tweet(tweet, host)
    
    replies_data = []
    raw_replies = getattr(tweet, 'replies', None) or []
    for r in raw_replies:
        try:
            replies_data.append(format_tweet(r, host))
        except Exception:
            pass

    return {
        "tweet": main_tweet,
        "replies": replies_data
    }

@app.route('/api/tweet_detail', methods=['GET'])
def get_tweet_detail():
    tweet_id = request.args.get('id', '').strip()
    host = request.host
    if not tweet_id:
        return jsonify({"status": "error", "message": "Tweet ID gerekli"}), 400
    try:
        detail = run_async(_async_get_tweet_detail(tweet_id, host))
        return jsonify({"status": "success", "data": detail})
    except Exception as e:
        logging.error(f"Tweet detay hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# --- 5. Arama (Search) ve Gündem (Trends) ---
async def _async_search(query, count, host):
    tweets = []
    try:
        tweets = await client.search_tweet(query, 'Top', count=count)
    except Exception as e1:
        logging.warning(f"Top arama başarısız ({e1}), Latest deneniyor...")
        try:
            tweets = await client.search_tweet(query, 'Latest', count=count)
        except Exception as e2:
            logging.error(f"Search başarısız: {e2}")
            raise e2

    results = []
    if tweets:
        for t in tweets:
            try:
                f = format_tweet(t, host)
                if f:
                    results.append(f)
            except Exception as fe:
                logging.warning(f"Arama tweet ayrıştırma hatası: {fe}")
    return results

@app.route('/api/search', methods=['GET'])
def search_tweets():
    query = request.args.get('q', '').strip()
    count = request.args.get('count', default=20, type=int)
    host = request.host
    if not query:
        return jsonify({"status": "error", "message": "Arama sorgusu gerekli"}), 400
    try:
        results = run_async(_async_search(query, count, host))
        logging.info(f"Arama tamamlandı: '{query}' için {len(results)} tweet bulundu.")
        return jsonify({"status": "success", "data": results})
    except Exception as e:
        logging.error(f"Arama hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

async def _async_get_trends():
    try:
        trends = await client.get_trends()
        result = []
        if trends:
            for tr in trends:
                name = getattr(tr, 'name', '') or str(tr)
                count = getattr(tr, 'tweets_count', '') or getattr(tr, 'tweet_count', '')
                result.append({
                    "name": clean_text_for_n9(name),
                    "count": str(count) if count else ""
                })
        return result
    except Exception as e:
        logging.warning(f"Gündem çekme hatası: {e}")
        return []

@app.route('/api/trends', methods=['GET'])
def get_trends():
    try:
        trends = run_async(_async_get_trends())
        return jsonify({"status": "success", "data": trends})
    except Exception as e:
        logging.error(f"Gündem hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# --- 6. Yer İmleri (Bookmarks) ---
async def _async_get_bookmarks(count, host):
    tweets = await client.get_bookmarks(count=count)
    return [format_tweet(t, host) for t in tweets]

@app.route('/api/bookmarks', methods=['GET'])
def get_bookmarks():
    count = request.args.get('count', default=20, type=int)
    host = request.host
    try:
        bookmarks = run_async(_async_get_bookmarks(count, host))
        return jsonify({"status": "success", "data": bookmarks})
    except Exception as e:
        logging.error(f"Yer imleri hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

async def _async_bookmark(tweet_id):
    return await client.bookmark_tweet(tweet_id)

@app.route('/api/bookmark', methods=['POST'])
def add_bookmark():
    data = request.json or {}
    tweet_id = str(data.get('id', '')).strip()
    if not tweet_id:
        return jsonify({"status": "error", "message": "Tweet ID gerekli"}), 400
    try:
        run_async(_async_bookmark(tweet_id))
        return jsonify({"status": "success", "bookmarked": True})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

async def _async_unbookmark(tweet_id):
    return await client.delete_bookmark(tweet_id)

@app.route('/api/unbookmark', methods=['POST'])
def remove_bookmark():
    data = request.json or {}
    tweet_id = str(data.get('id', '')).strip()
    if not tweet_id:
        return jsonify({"status": "error", "message": "Tweet ID gerekli"}), 400
    try:
        run_async(_async_unbookmark(tweet_id))
        return jsonify({"status": "success", "bookmarked": False})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# --- 7. Tweet Gönderme (Metin ve Görsel) ---
async def _async_create_tweet(text, media_path=None):
    media_ids = []
    if media_path and os.path.exists(media_path):
        m_id = await client.upload_media(media_path)
        media_ids.append(m_id)
    return await client.create_tweet(text=text, media_ids=media_ids if media_ids else None)

@app.route('/api/tweet', methods=['POST'])
def post_tweet():
    data = request.json or {}
    text = data.get('text', '').strip()
    b64_image = data.get('image', None)
    img_path = data.get('image_path', None)
    temp_img_path = None
    is_temp = False

    if not text and not b64_image and not img_path:
        return jsonify({"status": "error", "message": "Tweet metni veya görsel gerekli."}), 400

    try:
        if b64_image:
            temp_img_path = os.path.join(BASE_DIR, 'temp_upload.jpg')
            with open(temp_img_path, 'wb') as f:
                f.write(base64.b64decode(b64_image))
            is_temp = True
        elif img_path and os.path.exists(img_path):
            temp_img_path = img_path
            is_temp = False

        tweet = run_async(_async_create_tweet(text, temp_img_path))
        logging.info(f"Yeni tweet yayınlandı. ID: {tweet.id}")

        if is_temp and temp_img_path and os.path.exists(temp_img_path):
            os.remove(temp_img_path)

        return jsonify({"status": "success", "id": str(tweet.id)})
    except Exception as e:
        logging.error(f"Tweet gönderme hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# --- 8. Beğeni (Like / Unlike) ---
async def _async_like_tweet(tweet_id):
    resp = await client.favorite_tweet(tweet_id)
    try:
        r_json = resp.json()
        logging.info(f"★ X FavoriteTweet Yanıtı: {r_json}")
    except Exception:
        pass
    return resp

@app.route('/api/like', methods=['POST'])
def like_tweet():
    data = request.json or {}
    tweet_id = str(data.get('id', '')).strip()
    if not tweet_id:
        return jsonify({"status": "error", "message": "Tweet ID gerekli"}), 400
    try:
        run_async(_async_like_tweet(tweet_id))
        return jsonify({"status": "success", "liked": True})
    except Exception as e:
        logging.error(f"Beğeni hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

async def _async_unlike_tweet(tweet_id):
    resp = await client.unfavorite_tweet(tweet_id)
    try:
        logging.info(f"★ X UnfavoriteTweet Yanıtı: {resp.json()}")
    except Exception:
        pass
    return resp

@app.route('/api/unlike', methods=['POST'])
def unlike_tweet():
    data = request.json or {}
    tweet_id = str(data.get('id', '')).strip()
    if not tweet_id:
        return jsonify({"status": "error", "message": "Tweet ID gerekli"}), 400
    try:
        run_async(_async_unlike_tweet(tweet_id))
        return jsonify({"status": "success", "liked": False})
    except Exception as e:
        logging.error(f"Beğeni geri çekme hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# --- 9. Retweet (Retweet / Unretweet) ---
async def _async_retweet(tweet_id):
    try:
        resp = await client.retweet(tweet_id)
        logging.info(f"★ X CreateRetweet Yanıtı: {resp.json()}")
        return resp
    except Exception as e:
        if "327" in str(e) or "already retweeted" in str(e).lower():
            logging.info("Tweet zaten retweetlenmişti.")
            return True
        raise e

@app.route('/api/retweet', methods=['POST'])
def retweet():
    data = request.json or {}
    tweet_id = str(data.get('id', '')).strip()
    if not tweet_id:
        return jsonify({"status": "error", "message": "Tweet ID gerekli"}), 400
    try:
        run_async(_async_retweet(tweet_id))
        return jsonify({"status": "success", "retweeted": True})
    except Exception as e:
        logging.error(f"Retweet hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

async def _async_unretweet(tweet_id):
    resp = await client.delete_retweet(tweet_id)
    try:
        logging.info(f"★ X DeleteRetweet Yanıtı: {resp.json()}")
    except Exception:
        pass
    return resp

@app.route('/api/unretweet', methods=['POST'])
def unretweet():
    data = request.json or {}
    tweet_id = str(data.get('id', '')).strip()
    if not tweet_id:
        return jsonify({"status": "error", "message": "Tweet ID gerekli"}), 400
    try:
        run_async(_async_unretweet(tweet_id))
        return jsonify({"status": "success", "retweeted": False})
    except Exception as e:
        logging.error(f"Retweet silme hatası: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    load_session()
    host = os.environ.get("MEEX_HOST", "0.0.0.0")
    port = int(os.environ.get("MEEX_PORT", 5000))
    print("=" * 60)
    print("MeeX (Comprehensive Edition) Köprüsü Çalışıyor!")
    print(f"Yerel Ağ Erişimi: http://0.0.0.0:{port}/api")
    print("=" * 60)
    app.run(host=host, port=port, debug=False)
