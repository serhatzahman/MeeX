# MeeX — Nokia N9 İçin X (Twitter) İstemcisi

[![Lisans: MIT](https://img.shields.io/badge/Lisans-MIT-blue.svg)](LICENSE)
[![Platform: MeeGo 1.2 Harmattan](https://img.shields.io/badge/Platform-MeeGo%201.2%20Harmattan-cyan.svg)](https://en.wikipedia.org/wiki/MeeGo)
[![Stil: Sailfish OS Silica](https://img.shields.io/badge/Stil-Sailfish%20OS%20Silica-00D2C4.svg)](https://sailfishos.org/)
[![Python: 3.10+](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)

**MeeX**, efsanevi **Nokia N9 (MeeGo 1.2 Harmattan)** akıllı telefonu için özel olarak geliştirilmiş modern, açık kaynaklı bir X (Twitter) istemcisidir.

Resmi X API'sinin yüksek ücretlerine ve N9'un eskiyen TLS/SSL kütüphanelerine takılmadan; bilgisayarınızda çalışan hafif bir Python köprü sunucusu üzerinden tarayıcı oturum çerezleriyle doğrudan X'in dahili Web GraphQL uç noktalarına bağlanır.

---

*İngilizce dokümantasyon için lütfen [README.md](README.md) dosyasına bakınız.*

---

## 📸 Ekran Görüntüleri

| Zaman Tüneli (Akış) | Keşfet & Gündemler | Tweet Detayı & Yanıtlar |
|:---:|:---:|:---:|
| ![Akış](screenshots/01_timeline.png) | ![Keşfet](screenshots/02_explore_trends.png) | ![Yanıtlar](screenshots/03_tweet_detail.png) |

| Profil & Yer İmleri | Yeni Tweet Gönder | Uygulama Menüsü |
|:---:|:---:|:---:|
| ![Profil](screenshots/04_profile_bookmarks.png) | ![Gönder](screenshots/05_compose_tweet.png) | ![Menü](screenshots/06_nokia_n9_app_grid.png) |

---

## ✨ Özellikler

- **Sailfish OS (Silica UI) Tasarım Dili:**
  - Nokia N9'un AMOLED ekranına özel derin siyah zemin (`#080C12`).
  - Yarı saydam, yuvarlak köşeli cam efektli kart tasarımı.
  - İkonik **Pulley Menu** (*Aşağı çekerek yenileme* animasyonu ve etkileşimi).
  - Sailfish turkuazı (`#00D2C4`), beğeni pembesi (`#FF3366`), retweet yeşili (`#00E676`) ve yer imi sarısı (`#F59E0B`) renk vurguları.
  - Eylemlerde anında ekranda beliren **Sailfish Bildirim Kapsülü (Toast Notification)**.
- **Zengin Etkileşim ve Eylemler:**
  - **Zaman Tüneli:** Yazar adı, kullanıcı adı, tarih ve metin formatında anlık tweet akışı.
  - **Kapsül Eylem Butonları:** Tek dokunuşla **Beğen / Beğeniyi Kaldır** (♥), **Retweet / Retweeti Kaldır** (⇄) ve **Yer İmlerine Ekle / Çıkar** (★) aç-kapa mekanizması.
  - **Hızlı Yanıtla:** Yanıt butonuna dokunulduğunda ilgili kişinin `@kullaniciadi` hazır gelerek Yeni Gönderi ekranı açılır.
  - **Yeni Tweet Gönderimi:** 280 karakter sayaçlı rozet ve isteğe bağlı **Fotoğraf / Görsel Ekleme** alanı (📷).
- **Keşfet & Arama (Search & Trends):**
  - Sanal klavye onay desteğine sahip tweet, kullanıcı ve etiket arama çubuğu.
  - Canlı Türkiye / Dünya gündem konuları ve tweet sayıları; dokunulduğunda doğrudan arama yapar.
- **Tweet Detayı ve Yanıt Ağacı:**
  - Tweet metnine veya görseline dokunulduğunda tweet'in büyük görünümü ve altındaki tüm yanıt zinciri listelenir.
- **Kullanıcı Profil Sayfası ve Yer İmleri:**
  - Giriş yapan kullanıcı için 3 sekmeli modern arayüz:
    - **Hakkında:** Kapak resmi, avatar, biyografi, konum, katılma tarihi, takipçi/takip sayıları.
    - **Tweetler:** Kullanıcının kendi attığı son tweet'lerin listesi.
    - **Yer İmleri:** X'te kaydettiğiniz tüm yer imlerine (Bookmarks) doğrudan N9'dan erişim.
  - Akışta herhangi bir kullanıcının avatarına veya adına dokunulduğunda o kişinin profili açılır.
- **Nokia N9 Yerel Sistem Entegrasyonu:**
  - **Uygulama Menüsü Başlatıcısı:** Yerel `.desktop` dosyası ve 80x80 piksel Harmattan squircle ikonu (`meex.png`).
  - **Tek Komutla Ağdan Kurulum (OTA):** Sunucudan doğrudan `wget` ile cihaza saniyeler içinde kurulum imkanı.
  - **Çevrimdışı SQLite Önbelleği:** N9'un dahili QML SQLite motorunu kullanarak son tweet akışını depolar; Wi-Fi kesilse bile akışınızı okuyabilirsiniz.
- **Özel Uyumluluk Çözümleri:**
  - **Görsel & Avatar Köprüsü (Image Proxy):** Resimleri yerel ağdan HTTP ile sunarak N9'un eski SSL motorundaki `SSL handshake failed` hatasını tamamen çözer.
  - **Nokia N9 Emoji Temizleyici:** Modern emojileri N9 yazı tiplerinin tanıdığı sembollere çevirir (`♥`, `:D`, `[Alev]`), ekranda bozuk kare kutuların (`□`) çıkmasını engeller.
  - **X-Client-Transaction Yaması:** X'in yeni webpack JavaScript yapısını otomatik olarak çözen bellek içi düzenli ifade yaması.

---

## 🏗️ Mimari Şema

```
[ Nokia N9 (MeeGo Harmattan) ]
      │  (QtQuick 1.1 / PySide / QML)
      ▼  HTTP REST istekleri (Yerel Ağ)
[ MeeX.py Köprü Sunucusu ] (PC / Ev Sunucusu / Raspberry Pi)
      │  TLS 1.3 / Twikit / GraphQL
      ▼  Tarayıcı oturum çerezleriyle kimlik doğrulama
[ X (Twitter) Sunucuları ]
```

---

## 🚀 Kurulum ve Başlangıç

### 1. Adım: Köprü Sunucusunun Kurulumu (PC / Sunucu)

Gereksinim: Modern bir Python sürümü (3.10 veya üzeri).

1. **Gerekli Kütüphaneleri Yükleyin:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Oturum Çerezlerinizi Alın:**
   Bilgisayar tarayıcınızda [x.com](https://x.com) adresine giriş yapın:
   - Klavyeden `F12` tuşuna basarak Geliştirici Araçlarını açın.
   - **Application** (veya **Depolama**) > **Cookies (Çerezler)** > `https://x.com` yolunu izleyin.
   - **`auth_token`** değerini kopyalayın (~40 karakter).
   - **`ct0`** değerini kopyalayın (CSRF jetonu, ~160 karakter).

3. `cookies.json` dosyasını oluşturun (`cookies.json.example` dosyasını kopyalayın):
   ```json
   {
     "auth_token": "BURAYA_AUTH_TOKEN_DEGERINIZI_YAZIN",
     "ct0": "BURAYA_CT0_DEGERINIZI_YAZIN",
     "username": "KullaniciAdiniz"
   }
   ```
   *(Alternatif olarak `X_AUTH_TOKEN`, `X_CT0` ve `X_USERNAME` ortam değişkenlerini de tanımlayabilirsiniz).*

4. **Sunucuyu Başlatın:**
   - **Windows:** `start.bat` dosyasına çift tıklayın veya çalıştırın:
     ```cmd
     python MeeX.py
     ```
   - **Linux / macOS:**
     ```bash
     python3 MeeX.py
     ```
   Konsolda yazan yerel IP adresinizi not edin (örneğin: `http://192.168.1.100:5000`).

---

### 2. Adım: Nokia N9 Üzerine Kurulum

#### Yöntem A: Ağ Üzerinden Otomatik Kurulum (Önerilen)
Bilgisayarınızda `MeeX.py` sunucusu çalışırken, Nokia N9 cihazınızda Terminali açıp yetkili kullanıcıya geçin (`devel-su`, varsayılan şifre: `rootme`) ve şu komutu çalıştırın:
```bash
wget -qO- http://<BILGISAYAR_IP>:5000/install | sh
```
*(Komuttaki `<BILGISAYAR_IP>` yerine bilgisayarınızın yerel IP adresini yazın).*

#### Yöntem B: Dosyaları SCP ile Gönderme
Bilgisayarınızdan (PowerShell veya Terminal):
```bash
scp -O -oHostKeyAlgorithms=+ssh-rsa main.qml run.py meex.png meex.desktop user@<TELEFON_IP>:/home/user/
```
Ardından Nokia N9 root terminalinde:
```bash
mkdir -p /opt/MeeX /usr/share/applications /usr/share/icons/hicolor/80x80/apps
cp /home/user/main.qml /opt/MeeX/
cp /home/user/run.py /opt/MeeX/ && chmod +x /opt/MeeX/run.py
cp /home/user/meex.png /usr/share/icons/hicolor/80x80/apps/
cp /home/user/meex.desktop /usr/share/applications/
```

5. MeeX açıldığında alt çubuktaki **Ayarlar (⚙)** simgesine dokunarak sunucu adresinizi girin (örn: `http://192.168.1.100:5000/api`) ve **Kaydet ve Akışı Güncelle** butonuna basın.

---

## 📁 Proje Dosya Yapısı

```
├── MeeX.py               # Python köprü sunucusu (Flask + Twikit + Görsel Köprüsü)
├── main.qml              # Nokia N9 için Sailfish OS Silica QML arayüzü
├── meex.png              # 80x80 MeeGo Harmattan squircle uygulama ikonu
├── meex.desktop          # MeeGo Harmattan masaüstü başlatıcı dosyası
├── install_n9.sh         # Tek komutla N9 yerel kurulum betiği
├── run.py                # N9 için tam ekran PySide başlatıcı
├── start.bat             # Windows için tek tıkla başlatıcı
├── requirements.txt      # Gerekli Python kütüphaneleri
├── cookies.json.example  # Çerez şablon dosyası (kişisel bilgi barındırmaz)
├── meex_1.0.0_armel.deb  # Nokia N9 için hazır derlenmiş Debian paketi
├── screenshots/          # Uygulama ekran görüntüleri klasörü
│   ├── README.md         # N9 ekran görüntüsü alma kılavuzu
│   ├── 01_timeline.png
│   ├── 02_explore_trends.png
│   ├── 03_tweet_detail.png
│   ├── 04_profile_bookmarks.png
│   ├── 05_compose_tweet.png
│   └── 06_nokia_n9_app_grid.png
├── .gitignore            # Git yoksayma dosyası (çerezlerin sızmasını önler)
├── LICENSE               # MIT Lisansı
├── README.md             # İngilizce dokümantasyon
└── README_TR.md          # Türkçe dokümantasyon
```

---

## 📄 Lisans

Bu proje MIT Lisansı altında sunulmaktadır — ayrıntılar için [LICENSE](LICENSE) dosyasına bakabilirsiniz.
