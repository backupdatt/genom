# Panduan GENOM VPN Script

Panduan ini ditulis buat kamu yang mungkin baru pertama kali pegang script
ini — gak perlu jadi programmer buat ngikutin, tapi WAJIB dibaca urut dari
atas, jangan loncat-loncat.

---

## 📖 Istilah yang bakal sering muncul

| Istilah | Artinya |
|---|---|
| **VPS** | Server/komputer sewaan di internet, tempat VPN ini jalan 24 jam |
| **Script** | File kode (`.sh`, `.js`, `.py`) yang kalau dijalankan, komputer/VPS ngerjain sesuatu otomatis |
| **Repo (repository)** | "Folder besar" tempat semua file script ini disimpan di GitHub |
| **Public / Private (repo)** | Public = siapa aja bisa liat isi repo. Private = cuma kamu (dan yang kamu izinkan) yang bisa liat |
| **Token / API Key** | Semacam "kata sandi khusus" yang dipakai program buat login ke layanan lain (Google Drive, Cloudflare, GitHub, Telegram) tanpa kamu ketik password tiap saat |
| **Cron** | Jadwal otomatis di VPS — "jalanin script ini setiap 1 menit/1 hari" tanpa kamu harus nyalain manual |
| **`scp`** | Cara kirim file dari komputer kamu ke VPS lewat internet (mirip drag & drop, tapi lewat terminal) |
| **Placeholder** | Tulisan kayak `GANTI_INI_DULU` di dalam file — itu BUKAN kode asli, itu "kotak kosong" yang HARUS kamu isi sebelum dipakai |

---

## 🗺️ Gambaran besar — urutan yang harus kamu lakuin

Ikutin nomor ini **dari atas ke bawah**. Jangan skip.

1. ✅ **Install VPS** (kalau belum punya VPS yang jalan) → [STEP 1](#step-1-install-vps-baru)
2. ✅ **Isi semua "kotak kosong" (placeholder)** di file-file tertentu → [STEP 2](#step-2-isi-semua-kotak-kosong-placeholder)
3. ✅ **Pasang perbaikan anti-hang ke VPS** (cuma buat VPS LAMA) → [STEP 3](#step-3-pasang-perbaikan-anti-hang-ke-vps-cuma-buat-vps-lama)
4. ✅ **Atur sistem "izin pakai" biar jadi punya kamu sendiri** → [STEP 4](#step-4-atur-sistem-izin-pakai-lisensi)
5. 🔁 Kalau nanti mau update → [STEP 5](#step-5-kalau-nanti-mau-update)

Di paling bawah ada bagian **"Detail Teknis"** — itu buat yang penasaran
kenapa dulu server suka hang. Gak wajib dibaca buat bisa pakai script-nya.

---

## STEP 1: Install VPS baru

> Skip step ini kalau VPS kamu **udah jalan** — lanjut ke STEP 2.

1. Siapkan VPS baru (Debian/Ubuntu), punya akses `root`.
2. Login ke VPS lewat SSH, lalu jalankan:

   ```bash
   apt update && apt install -y curl wget
   cd /root
   wget https://raw.githubusercontent.com/backupdatt/genom/refs/heads/main/SYSTEM/ssh-vpn.sh
   chmod +x ssh-vpn.sh && ./ssh-vpn.sh
   ```

   > ⚠️ Kalau repo `backupdatt/genom` lagi di-set **Private** di GitHub,
   > command di atas bakal gagal (error "404"). Buka dulu jadi **Public**
   > sebentar (lihat kotak di STEP 5), baru jalanin, baru tutup lagi.

3. Tunggu ~10-15 menit sampai proses instalasi kelar. VPS akan otomatis
   install semua: SSH, Xray (vmess/vless/trojan), nginx, dll — **installer
   ini narik `limit-ip`/`proxy3.js`/`nginx.conf`/proxy websocket langsung
   dari repo final ini, jadi fresh install udah otomatis kebawa fix-nya.**
4. **Lanjut ke STEP 2** (isi placeholder). **STEP 3 BISA DI-SKIP** buat VPS
   baru kayak ini — lanjut aja ke **STEP 4** (atur lisensi).

---

## STEP 2: Isi semua "kotak kosong" (placeholder)

Beberapa file di repo ini masih ada tulisan `GANTI_INI_DULU` — itu artinya
**fitur itu gak akan jalan sampai kamu isi manual**. Ini daftarnya, mulai
dari yang paling penting:

### 2.1 🔑 Wajib — tanpa ini, buka menu di VPS jadi error

11 file menu ngecek "izin pakai" (anti-pakai-bajakan) setiap kali menu
dibuka. **Cara isinya ada lengkap di [STEP 4](#step-4-atur-sistem-izin-pakai-lisensi)
— baca itu dulu**, karena cara isinya BUKAN edit file satu-satu (biar gak
ketimpa tiap kali update), tapi lewat 1 file config terpisah di VPS.

### 2.2 💬 Supaya notifikasi Telegram jalan (lock multi-login, backup, dll)

Ini **bukan edit file**, tapi isi lewat menu di VPS:
1. Chat bot [@BotFather](https://t.me/BotFather) di Telegram → bikin bot baru → dapet **API Key**.
2. Chat bot [@userinfobot](https://t.me/userinfobot) → dapet **Chat ID / User ID** kamu.
3. Di VPS, buka menu `system` → cari opsi setting Telegram → masukin API Key & Chat ID itu.

Tanpa ini: notifikasi ke Telegram (misal pas ada user multi-login) **gagal
diam-diam**, gak ada pesan error yang kelihatan, cuma gak ada notif masuk.

### 2.3 ☁️ Cuma kalau mau pakai fitur SlowDNS

Buka file `SLOWDNS/installsl.sh`, cari 3 baris ini, isi pakai domain &
Cloudflare API key **punya kamu sendiri** (bukan punya orang lain):
```bash
DOMAIN=GANTI_DOMAIN_CLOUDFLARE_KAMU
CF_ID=GANTI_EMAIL_CLOUDFLARE_KAMU
CF_KEY=GANTI_CLOUDFLARE_API_KEY_KAMU
```
Cara dapet API Key: login ke [dashboard Cloudflare](https://dash.cloudflare.com/) →
klik ikon profil (kanan atas) → **My Profile** → **API Tokens** → lihat
**Global API Key**.

> ☁️ **Soal "Proxied" (ikon awan oranye) di Cloudflare:** gak perlu
> dinyalain, dan sebenarnya Cloudflare gak ngasih pilihan itu buat record
> tipe `NS` (yang dibuat script ini) — proxy/orange-cloud cuma berlaku
> buat A/AAAA/CNAME. Di `installsl.sh`, request ke Cloudflare API sudah
> hardcode `"proxied":false`, jadi record-nya otomatis "DNS only" (ikon
> abu-abu). Ini **wajib begitu** — SlowDNS butuh resolusi DNS langsung,
> gak bisa lewat proxy Cloudflare. Gak ada yang perlu kamu atur manual
> soal ini di dashboard Cloudflare.

Kalau kamu gak pakai fitur SlowDNS, skip bagian ini, gak masalah.

### 2.4 💾 Cuma kalau mau pakai fitur backup otomatis ke Google Drive

Dua file ini: `rc-clone` dan `SYSTEM/rclone.conf` — isinya placeholder
Google OAuth yang perlu diisi punya kamu sendiri:
1. Buka [Google Cloud Console](https://console.cloud.google.com/) → bikin
   **OAuth Client ID baru** → copy Client ID & Client Secret-nya ke file
   `rc-clone`.
2. Di VPS, jalankan `rclone config`, ikutin wizard-nya (pilih Google
   Drive), nanti keluar token → copy ke file `SYSTEM/rclone.conf`.

Kalau kamu gak butuh fitur backup ke Google Drive, skip bagian ini juga.

### 2.5 ℹ️ Boleh dibiarkan (opsional, gak wajib)

- `menu/menu.sh` punya baris `IPINFO_TOKEN="Abc12345"` — ini token contoh
  buat nampilin info lokasi/ISP di menu. Kalau dibiarkan, kadang gagal
  nampilin info (bukan bikin VPS error), cuma kurang akurat. Mau lebih
  bagus, daftar gratis di [ipinfo.io](https://ipinfo.io/signup), ganti
  tokennya.
- `SYSTEM/vars.conf` udah keisi email/nama kamu sendiri buat sertifikat
  OpenVPN — gak perlu diubah, cuma diingat itu email pribadi yang bakal
  kelihatan kalau repo-nya lagi dibuka Public.

### 2.6 🚫 Ad-block + anti-telemetry buat Xray (vmess/vless/trojan) — udah aktif otomatis

Fresh install (STEP 1) sekarang otomatis blokir domain-domain iklan DAN
tracking/telemetry umum (pakai `geosite:category-ads-all` +
`geosite:category-ads-and-telemetry`, dua-duanya daftar resmi dari
Xray-core) buat semua protokol berbasis Xray — vmess, vless, DAN trojan,
karena ketiganya share 1 `config.json` yang sama. **Gak ada yang perlu
kamu isi**, otomatis aktif.

Catatan:
- Ini **cuma berlaku ke vmess/vless/trojan**. User SSH murni (dropbear/
  OpenSSH) gak lewat Xray sama sekali, jadi gak ikut kena blokir ini —
  belum ditangani, di luar scope saat ini.
- Yang diblokir cuma domain ads/telemetry dari daftar resmi tadi (iklan
  di web/app/YouTube dkk + domain analytics/tracking perusahaan). Kalau
  ada iklan ISP yang nyuntik ke traffic HTTP biasa (bukan ini soalnya),
  itu otomatis ilang sendiri karena semua traffic vmess/vless/trojan/SSH
  udah terenkripsi — ISP gak bisa baca apalagi nyisipin apa-apa ke
  dalamnya.
- **Buat VPS yang udah jalan dari SEBELUM fitur ini ada**, tambahin manual
  di VPS: edit `/etc/xray/config.json`, taruh blok ini jadi rule PERTAMA
  di dalam `"routing": { "rules": [ ... ] }` (sebelum rule lain):
  ```json
  {
    "type": "field",
    "domain": ["geosite:category-ads-all", "geosite:category-ads-and-telemetry"],
    "outboundTag": "blocked"
  },
  ```
  Lalu `systemctl restart xray`.

### 2.7 🔒 Netflix dipaksa lewat IPv4 — jaga-jaga buat kalau VPS nanti dapet IPv6

VPS ini belum punya IPv6, tapi rule ini udah dipasang dari sekarang biar
siap kalau suatu saat IPv6 nyala (native dari provider atau tunnel
broker). Alasannya: kalau dual-stack aktif tapi blok IPv6-nya kebaca
negara yang salah sama database geolocation Netflix, device klien bakal
prefer IPv6 duluan (Happy Eyeballs) dan nentuin library Netflix dari situ
— walau IPv4-nya udah bener kebaca Indonesia. Rule ini maksa domain
Netflix (`netflix.com`, `nflxvideo.net`, dkk) selalu lewat outbound
`netflix-ipv4-only` (`sockopt.domainStrategy: "ForceIPv4"`), gak pernah
kebagian jalur IPv6 sama sekali — domain lain tetap bebas dual-stack
kalau IPv6 udah tersedia.

---

## STEP 3: Pasang perbaikan anti-hang ke VPS (cuma buat VPS LAMA)

> ℹ️ **Kalau VPS kamu baru di-install pakai STEP 1 (dari repo final ini),
> SKIP step ini** — semua perbaikan di bawah udah otomatis ketarik pas
> instalasi, gak perlu dikirim ulang. Lanjut aja ke STEP 4.
>
> Step ini **cuma relevan buat VPS yang udah ada/jalan dari SEBELUM** repo
> ini jadi versi final. Menu Update (`update.sh`, STEP 5) **belum**
> dirombak buat ikut nge-refresh file-file ini (sengaja dibiarkan apa
> adanya dulu) — jadi file di bawah ini masih harus dikirim manual.

Dulu server ini suka hang total kalau dipakai banyak orang bersamaan (RAM
kepenuhan, gak bisa respon). Itu udah dibenerin di file-file di repo ini —
**tapi perbaikannya cuma ada di folder ini (di komputer kamu), belum
otomatis masuk ke VPS yang lagi jalan.** Kamu harus kirim file-nya manual.

> Kalau mau tau detail teknis apa aja yang dibenerin & kenapa, baca
> [Lampiran: Detail Teknis Perbaikan](#-lampiran-detail-teknis-perbaikan)
> di paling bawah. Gak wajib dibaca buat bisa pasang fix-nya.

### Cara paling gampang: kirim file pakai `scp`

Jalankan ini dari **komputer kamu** (bukan dari VPS), ganti `IP_VPS` dengan
IP VPS kamu:

```bash
scp "TOOLS/limit-ip" root@IP_VPS:/usr/bin/limit-ip
scp "menu/xraylimit.sh" root@IP_VPS:/usr/bin/xraylimit
scp "menu/tendang.sh" root@IP_VPS:/usr/bin/tendang
scp "SYSTEM/xp.sh" root@IP_VPS:/usr/bin/xp
scp "SYSTEM/proxy3.js" root@IP_VPS:/etc/squid/squid.conf
scp "SYSTEM/nginx.conf" root@IP_VPS:/etc/nginx/nginx.conf
scp "WEBSOCKET/ws-dropbear" root@IP_VPS:/usr/local/bin/ws-dropbear
scp "WEBSOCKET/ws-ovpn.py" root@IP_VPS:/usr/local/bin/ws-ovpn
scp "WEBSOCKET/ws-stunnel" root@IP_VPS:/usr/local/bin/ws-stunnel
```

Lalu, **di VPS**, jalankan ini biar semua file bisa dieksekusi:
```bash
chmod +x /usr/bin/limit-ip /usr/bin/xraylimit /usr/bin/tendang /usr/bin/xp \
         /usr/local/bin/ws-dropbear /usr/local/bin/ws-ovpn /usr/local/bin/ws-stunnel
```

Pasang juga pembatas ukuran log biar gak numpuk lagi (**di VPS**):
```bash
cat > /etc/logrotate.d/xray <<-END
/var/log/xray/access.log /var/log/xray/error.log /var/log/xray/access2.log /var/log/xray/error2.log {
    daily
    rotate 3
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
    maxsize 100M
}
END
chmod 644 /etc/logrotate.d/xray
```

Kalau log-nya udah kebesaran dari dulu, kosongkan dulu manual:
```bash
echo -n > /var/log/xray/access.log
```

Terakhir, restart semua service yang kena perbaikan (**di VPS**):
```bash
systemctl daemon-reload
systemctl restart vmip vlip trip
systemctl restart xray nginx
systemctl restart ws-dropbear ws-ovpn ws-stunnel
service cron reload
```

### Cek apakah berhasil

```bash
# proses limit-ip harusnya jalan terus, gak restart-restart tiap detik
systemctl status vmip vlip trip

# pantau pemakaian RAM setelah beberapa jam dipakai banyak user
free -h
```

---

## STEP 4: Atur sistem izin pakai (lisensi)

Dulu, setiap kali menu dibuka, VPS ini ngecek "boleh dipakai atau gak" ke
server GitHub **punya orang lain** (penulis script aslinya) — artinya
mereka tahu daftar IP VPS kamu, dan bisa mencabut akses kamu kapan aja.
Sekarang itu udah diganti supaya ngecek ke **server GitHub punya kamu
sendiri**.

> ⚠️ **Penting — JANGAN edit placeholder `GH_USER`/`GH_REPO`/`GH_TOKEN`
> langsung di 11 file menu itu.** File-file itu ikut di-refresh tiap kamu
> jalanin menu Update (STEP 5) dari repo ini — kalau token asli kamu
> ditulis di situ, dia bakal **ketimpa balik jadi placeholder** tiap
> update, dan kamu harus isi ulang manual terus-terusan. Taruh token kamu
> di **1 file config terpisah** yang gak pernah disentuh proses update
> (langkah 4 di bawah).

### Langkah setup

1. **Bikin repo GitHub baru, set-nya ke Private.** Nama bebas, misal
   `lisensi-vpn`.
2. **Bikin "Personal Access Token" (PAT)** — ini kayak kunci khusus biar
   VPS bisa baca repo private kamu:
   - Buka GitHub → foto profil (kanan atas) → **Settings** → **Developer
     settings** → **Personal access tokens** → **Fine-grained tokens** →
     **Generate new token**.
   - Kasih akses cuma ke repo `lisensi-vpn` itu aja (jangan pilih "All
     repositories").
   - Di bagian Permission, pilih **Contents → Read-only**.
   - Klik Generate, **copy token-nya sekarang** (cuma muncul sekali!).
3. **Bikin 2 file di repo private itu** (lewat tombol "Add file" di
   GitHub), isinya daftar IP VPS yang boleh pakai:
   - File namanya `gnome` — isi:
     ```
     ### NamaKlien 2027-12-31 103.21.44.10
     ```
     (ganti `NamaKlien` = nama kamu, `2027-12-31` = tanggal kadaluarsa,
     `103.21.44.10` = IP VPS kamu — cek IP VPS dengan command
     `curl ipv4.icanhazip.com` di VPS)
   - File namanya `genom-pro` — isinya format sama, baris yang sama juga
     (file ini khusus dipakai oleh menu `admin`).
4. **Di VPS kamu (bukan di repo ini), bikin file baru** `/etc/xray/license.conf`
   isinya:
   ```bash
   GH_USER="username_github_kamu"
   GH_REPO="lisensi-vpn"
   GH_TOKEN="token_dari_langkah_2"
   ```
   File ini **cuma ada di VPS, gak pernah masuk ke repo/git, gak pernah
   ketimpa update.** Cukup bikin SEKALI, selesai selamanya — ini jawaban
   kenapa kamu gak perlu maintenance teknis berulang-ulang buat lisensi.
5. **Tes dulu di VPS** sebelum dipakai beneran:
   ```bash
   source /etc/xray/license.conf
   curl -s -H "Authorization: token $GH_TOKEN" \
     -H "Accept: application/vnd.github.v3.raw" \
     "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/gnome?ref=main"
   ```
   Kalau berhasil, bakal muncul isi file `gnome` kamu. Kalau muncul error
   (404/401), cek lagi token/nama repo/username-nya.

**Kalau nanti mau kasih akses ke VPS orang lain:** tinggal tambah baris
baru di file `gnome`/`genom-pro` (IP VPS dia + tanggal expired). Mau
cabut akses dia, hapus/edit baris itu aja — gak perlu sentuh VPS-nya sama
sekali.

---

## STEP 5: Kalau nanti mau update

```bash
cd /root
rm -f update
wget https://github.com/backupdatt/genom/raw/refs/heads/main/menu/update.sh -O update
chmod +x update && ./update
```

> ⚠️ **PENTING — baca ini:** `update.sh` cuma nge-refresh file **menu CLI**
> (`menu`, `m-vmess`, `sshws`, `xraylimit`, `admin`, dll — termasuk 11 file
> lisensi di STEP 4). Dia **TIDAK** nyentuh `TOOLS/limit-ip`,
> `SYSTEM/proxy3.js`, `SYSTEM/nginx.conf`, proxy websocket, `SYSTEM/xp.sh`,
> maupun logrotate — itu masih harus ditangani manual lewat STEP 3 kalau
> ada fix baru ke file-file itu di kemudian hari. Juga, command ini narik
> dari GitHub, jadi kamu harus **push** dulu perbaikan di STEP 3 & 4 ke
> repo `backupdatt/genom`, kalau belum, jalanin ini bakal nimpa balik
> ke versi lama.

### Soal buka/tutup repo Public-Private

Banyak script di sini (`ssh-vpn.sh`, `update.sh`, dll) narik file dari
GitHub pakai cara biasa yang cuma jalan kalau repo-nya **Public**. Kalau
kamu sengaja bikin repo `backupdatt/genom` jadi Private (biar gak
sembarangan dibuka orang), buka dulu sebentar pas mau install/update, baru
tutup lagi:

```bash
gh repo edit backupdatt/genom --visibility public   # sebelum install/update
gh repo edit backupdatt/genom --visibility private  # tutup lagi setelah selesai
```

(File lisensi `gnome`/`genom-pro` dari STEP 4, dan `/etc/xray/license.conf`
di VPS, itu beda — **selalu private**, gak ikut buka-tutup ini.)

---

## 📎 Lampiran: Detail Teknis Perbaikan

> Bagian ini buat yang penasaran kenapa dulu server suka hang. Kalau cuma
> mau pakai script-nya, kamu gak perlu baca ini.

Dulu server bisa hang total kalau dipakai banyak user bersamaan — RAM &
cache naik terus sampai gak bisa respon apa-apa. Setelah investigasi penuh
ke semua script di `SYSTEM/`, `TOOLS/`, `WEBSOCKET/`, dan `menu/`, ketemu
akar masalahnya:

| # | Masalah | File | Perbaikan |
|---|---------|------|-----|
| 1 | `limit-ip` (service `vmip`/`vlip`/`trip`) di-set `Restart=always` tapi gak ada loop di dalam script-nya → begitu selesai jalan sekali, langsung mati lalu dihidupin ulang sistem OS tanpa henti, numpuk proses tiap detik | `TOOLS/limit-ip` | Dibungkus `while true; do ...; sleep 10; done` sendiri, gak lagi andalin sistem buat "mengulang"-nya |
| 2 | Jadwal otomatis `xraylimit` & `tendang` jalan tiap 1 menit, baca SELURUH file log (yang gak pernah dibersihkan) tiap kali jalan, tanpa penanda "masih jalan atau udah selesai" — bisa numpuk kalau lambat | `menu/xraylimit.sh`, `menu/tendang.sh` | Ditambah penanda anti-tumpuk + baca log cuma bagian terakhir, gak baca semua |
| 3 | Log Xray gak pernah dibersihkan/dipotong sejak awal → makin lama makin besar, makin berat dibaca | `SYSTEM/ins-xray.sh` | Auto-pasang pembersih log otomatis (harian, max 100MB) |
| 4 | Jadwal otomatis buat "kunci user yang login ganda" numpuk selamanya, gak pernah hapus diri sendiri | `menu/xraylimit.sh` | Tiap jadwal sekarang hapus dirinya sendiri setelah jalan sekali |
| 5 | Jadwal harian restart Xray 3x berturut-turut → bisa bikin semua user ter-disconnect berkali-kali | `SYSTEM/xp.sh` | Disisakan cuma 1x restart di akhir |
| 6 | Waktu percobaan (trial) dalam menit bisa diisi `0` tanpa validasi → bikin jadwal otomatis rusak/numpuk proses | `menu/sshws.sh`, `menu/m-vmess.sh`, `menu/m-vless.sh`, `menu/m-trojan.sh` | Angka di bawah 1 dipaksa jadi default 5 menit |
| 7 | Satu proses (`proxy3.js`) "membersihkan memori" tiap 1 detik terus-terusan (gak nyelesain masalah aslinya, cuma nambah beban), plus gak ada batas jumlah koneksi | `SYSTEM/proxy3.js` | Pembersihan paksa dihapus, ditambah batas maksimal 2000 koneksi |
| 8 | Nginx cuma pakai 1 inti CPU buat semua trafik → jadi bottleneck pas banyak orang pakai bersamaan | `SYSTEM/nginx.conf` | Diubah pakai semua inti CPU yang tersedia |
| 9 | Proxy websocket bikin 1 "pekerja" baru buat tiap koneksi masuk tanpa batas → RAM naik terus sesuai jumlah koneksi | `WEBSOCKET/ws-dropbear`, `ws-ovpn.py`, `ws-stunnel` | Ditambah batas maksimal 1500 koneksi |
| 10 | Token lisensi (`GH_TOKEN`) kalau ditulis langsung di 11 file menu, ketimpa jadi placeholder lagi tiap `update.sh` jalan | `11 file menu lisensi` | Token dipisah ke `/etc/xray/license.conf` di VPS, gak ikut di-refresh |
| 11 | `menu/update.sh` menarik `/usr/bin/xp` dari `menu/xp` (versi lama, restart Xray 3x), bukan dari `SYSTEM/xp.sh` (versi fix #5) — kalau `update.sh` dijalankan di VPS yang sebelumnya udah dipasangi fix #5 manual, fix itu ketimpa balik | `menu/update.sh` | Diganti narik dari `SYSTEM/xp.sh`, `menu/xp` (file lama) dihapus dari repo |

**Yang sengaja belum dibenerin** (dampaknya kecil karena dipanggil manual,
bukan jadwal otomatis): beberapa menu cek status online (`online-trojan`,
`online-vless`, dst) masih baca log dengan cara agak berat, dan proses
jaringan UDP pihak ketiga (`badvpn`, `udp-custom`, `udp-mini`) dikenal bisa
makan memori per koneksi aktif — ini di luar kendali kode script (program
pihak ketiga).

---

## 🆕 Masalah Umum Pas Fresh Install VPS Baru

> Ditemukan pas install ulang dari nol ke VPS baru (Herza, Nov 2026).
> Install `ssh-vpn.sh` + `ins-xray.sh` sendiri jalan lancar, tapi beberapa
> hal ini **gak otomatis kebawa** dan baru ketahuan pas dites manual.

| # | Masalah | Kapan ketahuan | Perbaikan |
|---|---------|-----------------|-----------|
| 1 | `apt install iptables-persistent` di `ins-xray.sh` nge-hang nunggu prompt debconf ("save rules IPv4/IPv6?") kalau dijalankan lewat SSH non-interaktif (`DEBIAN_FRONTEND=noninteractive` gak di-set di script ini, beda sama `ssh-vpn.sh`) | Install macet ~5 menit di langkah ini tanpa progress | `echo 'iptables-persistent iptables-persistent/autosave_v4 boolean true' \| debconf-set-selections` (sama buat v6) sebelum install, atau kill proses yang nge-hang lalu `dpkg --configure iptables-persistent` manual |
| 2 | Xray gagal start: `permission denied` buka `/var/log/xray/access.log` — folder log dibuat punya `xray:xray` (`700`), tapi systemd unit jalanin xray sebagai `www-data` | `systemctl status xray` nunjuk exit code 23 | `chown -R www-data:www-data /var/log/xray && chmod 755 /var/log/xray` |
| 3 | `ws-stunnel.service` hardcode port **701**, padahal nginx proxy ke port **700** — bikin landing page/download-link `.txt` kena 502 terus | Akses domain lewat browser selalu 502 | Edit `ExecStart=.../ws-stunnel 701` jadi `700` di `/etc/systemd/system/ws-stunnel.service`, lalu `daemon-reload` + restart |
| 4 | `/home/vps` permission `750` punya `vps:vps` — nginx (`www-data`) gak bisa *traverse* masuk sama sekali, walau `public_html` di dalemnya udah `775` | Semua file `.txt`/`.ovpn` kena 403, walau filenya ada | `chmod o+x /home/vps` (cukup tambah execute buat others, gak perlu ubah rwx lain) |
| 5 | Nginx `/vless-xhttp`, `/vmess-xhttp` gak punya `proxy_read_timeout` sendiri → kena default nginx 60s, padahal XHTTP butuh koneksi long-lived. Berujung banyak user "disconnect" bareng pas lagi aktif connect | Muncul manual, pas banyak user connect bersamaan dalam durasi lama | Tambah `proxy_read_timeout 300s; proxy_send_timeout 300s; proxy_buffering off; proxy_request_buffering off;` di location block `/vless-xhttp` & `/vmess-xhttp` |
| 6 | Command `menu` gak ada — `ssh-vpn.sh` cuma download `issue`, `m-theme`, `speedtest`, `xp` ke `/usr/bin`, **gak pernah download `menu/menu.sh` jadi `/usr/bin/menu`** | `menu` → "command not found" | Copy manual: `cp menu/menu.sh /usr/bin/menu && chmod +x /usr/bin/menu` (plus isi `/etc/xray/license.conf`, lihat STEP 4) |
| 7 | Dashboard nunjuk City/ISP kosong terus — `status.sh`/`lib-ipinfo.sh` baca token IPinfo dari `grep ... /usr/bin/menu`, jadi otomatis kosong kalau masalah #6 belum dibenerin | Field City/ISP di dashboard selalu blank | Beres sendiri begitu masalah #6 dibenerin (token-nya emang hardcoded di `menu.sh`) |
| 8 | Dashboard nunjuk IP VPS kosong — provider ngasih 2 nameserver di `/etc/netplan/*.yaml`, nameserver PERTAMA mati total (`timeout`), bikin tiap curl ke `icanhazip.com` nunggu lama/gagal sebelum fallback ke yang kedua | Field IP di dashboard selalu blank, `curl: (28) Resolving timed out` | Cek nameserver satu-satu (`timeout 5 nslookup host NAMESERVER_IP`), ganti yang mati di `/etc/netplan/*.yaml` (bukan cuma `/etc/resolv.conf`, biar gak ketimpa pas reboot), lalu `netplan apply` |
| 9 | File config publik `vless-<user>.txt` gak ada (404) buat akun yang ditambahin langsung lewat `config.json` (migrasi manual/script), karena generate file ini ada di `menu/m-vless.sh` (dipanggil pas create via menu CLI), BUKAN di `TOOLS/bot/account.sh` (dipanggil via Telegram bot) | Link download config 404 walau akun-nya valid & bisa connect | Generate ulang manual pakai template di `menu/m-vless.sh` (baris `cat > /home/vps/public_html/vless-$user.txt <<-END ... END`) buat tiap user yang di-migrasi manual |
| 10 | Migrasi akun antar-server (copy UUID+expiry dari server A ke config.json server B) **harus insert ke 5 marker vless** (`#vl`, `#vlg`, `#vlup`, `#vlxh`, `#vlrl`), persis di titik anchor yang sama kayak `account.sh` create (`#vless$`, `#vlessgrpc$`, `#vlessup$`, `#vlessxhttp$`, `#vlessreality$`) — kalau cuma sebagian, akun kelihatan ada tapi protokol tertentu gak jalan | Ketauan pas bandingin jumlah marker (`grep -c '^#vlxh '` dkk) beda-beda antar protokol buat user yang sama | Insert ke SEMUA 5 anchor sekaligus pakai 1 script, verifikasi `grep -c` tiap marker hasilnya sama rata |
| 11 | Dashboard "Online"/jumlah-IP per user selalu `0 IP` walau request-nya banyak — `config.json` fresh install gak punya `"sockopt": { "trustedXForwardedFor": ["X-Forwarded-For"] }` di `streamSettings` tiap inbound WS/gRPC/HTTPUpgrade/XHTTP, jadi `access.log` xray cuma nyatet `127.0.0.1` (koneksi lokal dari nginx), bukan IP publik asli — `online.sh`'s `extract_ip()` nge-filter `127.*` sebagai loopback. Fix-nya udah ada di `CHANGELOG.md` tapi gak ke-generate otomatis sama `ins-xray.sh` | Dashboard nunjuk `0 IP` di semua akun walau "X request" jalan terus | Insert `sockopt` itu ke tiap inbound WS/gRPC/HTTPUpgrade/XHTTP (bukan yang `tcp,udp` atau REALITY) di `/etc/xray/config.json`, lalu `systemctl restart xray`. Verifikasi: `tail /var/log/xray/access.log` harus nunjuk IP publik asli, bukan `127.0.0.1` |

> **Boleh diabaikan di fresh install:** `/usr/bin/autocpu`, `/usr/bin/bottelegram`,
> `/usr/bin/tendang`, `/usr/bin/xraylimit` — semua ini legacy/dead feature
> (SSH-tunnel multi-login kicker & IP-limit lama), dicek dan ternyata
> gak dipakai aktif sama sekali bahkan di server production asli (Biznet):
> gak ada akun SSH-tunnel customer beneran, dan `xraylimit` udah digantikan
> `TOOLS/bot/iplimit-daemon.py`. Gak perlu diinstall ulang pas setup server baru.

---

## 📋 Changelog

Riwayat lengkap tiap perubahan (termasuk yang dicoba lalu di-revert) udah
dipindah ke file terpisah, biar README ini gak kepanjangan:

➡️ **[Lihat CHANGELOG.md](CHANGELOG.md)**

