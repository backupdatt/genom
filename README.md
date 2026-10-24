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

### 2.6 🚫 Ad-block buat Xray (vmess/vless/trojan) — udah aktif otomatis

Fresh install (STEP 1) sekarang otomatis blokir domain-domain iklan umum
(pakai `geosite:category-ads-all`, daftar resmi dari Xray-core) buat semua
protokol berbasis Xray — vmess, vless, DAN trojan, karena ketiganya share
1 `config.json` yang sama. **Gak ada yang perlu kamu isi**, otomatis aktif.

Catatan:
- Ini **cuma berlaku ke vmess/vless/trojan**. User SSH murni (dropbear/
  OpenSSH) gak lewat Xray sama sekali, jadi gak ikut kena blokir ini —
  belum ditangani, di luar scope saat ini.
- Yang diblokir cuma domain ads dari daftar resmi tadi (iklan di
  web/app/YouTube dkk). Kalau ada iklan ISP yang nyuntik ke traffic HTTP
  biasa (bukan ini soalnya), itu otomatis ilang sendiri karena semua
  traffic vmess/vless/trojan/SSH udah terenkripsi — ISP gak bisa baca
  apalagi nyisipin apa-apa ke dalamnya.
- **Buat VPS yang udah jalan dari SEBELUM fitur ini ada**, tambahin manual
  di VPS: edit `/etc/xray/config.json`, taruh blok ini jadi rule PERTAMA
  di dalam `"routing": { "rules": [ ... ] }` (sebelum rule lain):
  ```json
  {
    "type": "field",
    "domain": ["geosite:category-ads-all"],
    "outboundTag": "blocked"
  },
  ```
  Lalu `systemctl restart xray`.

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

**Diketahui tapi SENGAJA belum dibenerin (keputusan ditunda):**
- `menu/update.sh` menarik `/usr/bin/xp` dari `menu/xp` (script hapus-user
  biasa), bukan dari `SYSTEM/xp.sh` (versi yang fix #5 di atas). Kalau
  `update.sh` pernah dijalankan di VPS yang sebelumnya sudah dipasangi fix
  #5 secara manual (STEP 3), fix itu **akan ketimpa balik**. Belum
  diperbaiki karena `update.sh` sengaja belum disentuh untuk sementara.

**Yang sengaja belum dibenerin** (dampaknya kecil karena dipanggil manual,
bukan jadwal otomatis): beberapa menu cek status online (`online-trojan`,
`online-vless`, dst) masih baca log dengan cara agak berat, dan proses
jaringan UDP pihak ketiga (`badvpn`, `udp-custom`, `udp-mini`) dikenal bisa
makan memori per koneksi aktif — ini di luar kendali kode script (program
pihak ketiga).

---

## 📋 Changelog

Format ikut [Keep a Changelog](https://keepachangelog.com/).

### [2026-10-25]

#### 🔒 Security — Xray kepasang versi yang ditarik XTLS, update ke stable
Versi xray di VPS (`26.10.17`) ternyata udah ditarik XTLS karena ikut percaya sertifikat yang private key-nya kebobol; `SYSTEM/ins-xray.sh` juga ketauan ambil versi dari endpoint GitHub yang gak dijamin stable, sekarang difix. Pas update ke `26.10.21`, ketemu bug installer resmi yang reset path config xray ke lokasi kosong (langsung diperbaiki + dibikin otomatis-kefix di script biar gak kejadian lagi).

#### ✨ Added — Restore akun expired (CLI, Telegram bot, web dashboard)
Dulu akun expired langsung dihapus permanen tanpa jalan balik, ketauan masalahnya pas 1 akun customer kehapus gak sengaja. Sekarang `expiry-enforce.sh` arsipkan dulu selama 7 hari sebelum beneran dihapus, dan bisa di-restore pakai UUID yang sama lewat CLI, bot Telegram, atau dashboard web.

#### 🐛 Fixed — Traceback panjang di log webapi gara-gara klien disconnect
Klien yang nutup koneksi di tengah request bikin traceback 20-baris nongol di log, padahal itu perilaku normal bukan bug. Sekarang dibungkus jadi 1 baris log yang jelas.

### [2026-10-21]

#### ✨ Added — Pemakaian bandwidth: hari ini/kemarin/bulan ini (per-akun & server)
User nanya ada info total kuota terpakai (hari ini/kemarin/bulanan)
gak. Dicek dulu: sistem lama cuma simpen 1 angka kumulatif seumur
hidup akun (buat enforcement quota doang), gak ada histori harian
sama sekali.
- **Ketemu bug pre-existing**: mekanisme usage-tracking lama
  (`xraylimit.sh` → `/etc/limit/<proto>/<user>`) ternyata **gak
  pernah jalan** di VPS ini — gate-nya pakai heuristik timestamp log
  yang rapuh (mirip masalah CGNAT yang udah ditemu sebelumnya di
  sesi ini) dan gak pernah match walau ada 11 akun vless aktif
  beneran. Jadi fitur auto-delete-saat-lewat-quota kemungkinan besar
  **gak pernah beneran enforce** — ini temuan terpisah, di luar
  scope kerjaan ini, FYI aja buat ditindaklanjuti kalau mau.
- Dibangun pipeline baru yang independen, gak gantungan sama
  `xraylimit.sh`:
  - `usage-collect.sh` (cron tiap 5 menit): ambil uplink+downlink
    langsung dari Xray stats API native (`xray api stats ... -reset`),
    akumulasi ke `/etc/xray-usage/total/<proto>/<user>`.
  - `usage-snapshot.sh` (cron harian): snapshot total itu tiap hari,
    biar bisa dihitung selisih "sekarang vs tengah malam
    hari-ini/kemarin/tanggal-1-bulan-ini".
  - `usage.sh`: query interface (`account`/`server`), dipakai
    `account.sh info`, endpoint baru `/dashboard/api/usage`, dan bot.
- Ditangani kasus "fitur baru aktif di tengah bulan/hari": delta
  cuma dihitung kalau snapshot baseline-nya BENERAN ada di disk,
  kalau nggak langsung 0 — biar hari pertama gak salah nampilin
  total seumur hidup akun sebagai "kemarin". "Bulan ini" jatuh ke
  snapshot paling awal yang ada (bukan harus nunggu tanggal 1 beneran
  tiba), jadi langsung jalan dari hari pertama.
- Tampil di **web dashboard** (panel baru "Pemakaian Bandwidth" +
  tambahan di modal Info Akun) dan **Telegram bot** (Status Server +
  Info Akun). Diverifikasi end-to-end: angka cross-check manual ke
  `xray api stats` langsung, growth kebukti lewat re-run collector,
  tampilan dicek via Playwright screenshot (bukan cuma curl).

#### ✨ Added — Dashboard auto-refresh tiap 5 detik (bukan WebSocket)
User nanya bisa dibuat realtime pakai WebSocket. Dicek dulu: angka
server (Uptime/RAM/CPU/Disk/Online Now/jumlah akun) emang selalu
dihitung live tiap request (gak di-cache), tapi `history.json` buat
line chart cuma di-generate cron 1x/menit — jadi "ambil tiap 5 detik"
cuma masuk akal buat angka, bukan grafik.
- Dashboard sekarang polling `loadDashboard()` tiap 5 detik otomatis
  selama halaman Dashboard kebuka, berhenti pas pindah halaman atau
  tab di-minimize (`visibilitychange`), biar gak boros request pas
  gak kepake.
- WebSocket beneran **sengaja gak dipakai** — butuh implementasi
  protokol WS manual di `webapi.py` (masih stdlib-only, gak ada
  dependency) + ubah nginx buat proxy upgrade header, demi manfaat
  yang kecil buat skala 1-2 admin. Polling tiap 5 detik buat payload
  JSON kecil itu beban yang diabaikan.
- Ketemu & fix 1 bug pas bikin ini: pagination "Online Sekarang"
  ke-reset ke halaman 1 tiap `loadDashboard()` jalan — kalau gak
  diperbaiki, polling 5 detik bakal narik admin balik ke halaman 1
  terus kalau lagi liat halaman 2+. Diverifikasi via Playwright:
  endpoint status kepanggil ~tiap 5 detik, dan posisi halaman Online
  Now tetap bertahan.

#### 🐛 Fixed — Tombol Aksi tabel Akun kepotong di mobile (ketauan via Playwright)
Playwright akhirnya konek lagi, jadi fix responsive di atas ini
beneran dites visual (375px/768px/1440px), bukan cuma baca kode.
Ketemu 1 bug nyata yang kelewat: 4 tombol aksi (Info/Renew/Limit/
Hapus) di tabel Akun kepotong di tepi layar HP — ternyata
`overflow-x:auto` di `.table-wrap` gak pernah "nangkep" overflow-nya
karena tombol-tombolnya cuma wrap ke baris baru di dalam cell sempit
alih-alih bikin tabel beneran lebih lebar dari layar. Fix: kasih
`table { min-width: 560px }` biar scroll-nya jalan beneran, + cegah
baris tombol Aksi ikut wrap. Diverifikasi scroll kanan nampilin 4
tombol utuh, dan semua halaman (Dashboard, Akun, Trial, Logs, modal
Buat Akun) dicek bersih di 3 ukuran layar.

#### ✨ Added — Dashboard responsive di semua device
Dashboard sebelumnya cuma punya `<meta viewport>` doang — sidebar
236px fixed + layout desktop-only, belum dites beneran di HP. Gak
pakai framework CSS (masih custom design system dari sesi sebelumnya),
cuma ditambah breakpoint & perilaku adaptif:
- Sidebar jadi drawer off-canvas di bawah 860px, dibuka lewat tombol
  hamburger di topbar mobile baru, nutup otomatis pas tap backdrop
  atau pindah halaman.
- `.table-wrap` ternyata pakai `overflow: hidden` (bukan `overflow-x:
  auto`) — table akun sebenarnya NGGAK bisa di-scroll di layar
  sempit sejak awal, baru ketauan & dibenerin sekarang.
- Modal dibatasi `min(Npx, 100vw-32px)` + max-height+scroll, jadi
  gak overflow di HP kecil atau layar pendek.
- `page-head`, `svc-row` (termasuk baris Online Now), `table-foot`
  ditambah `flex-wrap` biar teks panjang (lokasi/ISP, dll) gak
  kepotong di layar sempit.
- Grid ringkasan akun (VMess/VLess/Trojan) drop dari fixed 3 kolom
  jadi auto-fit di bawah 860px.

### [2026-10-20]

#### 🐛 Fixed — Process-leak CLI menu, ronde 2 (ternyata belum tuntas)
User nanya ulang "udah beneran aman?" dan jawabannya waktu itu
**belum** — audit ulang nemu banyak titik bocor lain yang kelewat
di fix pertama (commit `f6b887e`):
- `menu.sh` sendiri ternyata forward ke SEMUA submenu (`sshws`,
  `m-vmess`, `m-vless`, `m-trojan`, `menu-backup`, `cekservice`,
  `running`, `m-update`, `system`, `online`, `admin`) tanpa `exec` —
  karena submenu-submenu itu udah `exec` balik ke `menu`, proses
  `menu.sh` yang lama jadi nunggu selamanya tiap user masuk ke
  submenu apapun. Ini yang paling parah, kena di SETIAP navigasi.
- 3 halaman "Cek Login IP" di `m-trojan.sh`/`m-vless.sh`/`m-vmess.sh`
  manggil ulang nama binary-nya sendiri di baris mandiri (bukan di
  dalam `case`), kelewat di scan pertama yang cuma nyari pola
  `case ... ;;`.
- Ketemu juga 2 dispatcher yang di repo ini cuma ada **tanpa** ekstensi
  `.sh` (`menu-backup`, `online`) — punya bug identik di semua
  opsinya, termasuk forward navigation ke backup/restore/atur-backup
  dan online-vmess/vless/trojan/xray/ceklimit.
- `system.sh` masih punya 2 titik `clear ; m-theme ;;` yang belum
  ke-exec dari fix pertama.
- Semua call yang manggil FUNGSI LOKAL (bukan binary lain) sengaja
  dibiarkan — dicek satu-satu, aman karena gak fork proses baru.
- Diverifikasi ulang di VPS: simulasi `exec menu` gak nambah proses
  numpuk lagi.

#### ✨ Added — Pagination Online Now (5 per halaman)
List "Online Sekarang" ternyata bisa panjang (10+ akun aktif sekaligus)
dan gak enak di-scroll dalam 1 blok panjang. Ditambah Prev/Next, 5 akun
per halaman — web dashboard (tombol di atas panel) dan Telegram bot
(inline keyboard, sama kayak pagination list Akun).

#### ✨ Added — Total device terkoneksi (Online Now)
- **Web dashboard**: panel "Online Sekarang" nambah ringkasan
  "N akun aktif · M device total" (jumlah `ip_count` semua akun yang
  online), jadi gak cuma liat per-akun tapi total device beneran yang
  nyambung sekarang.
- **Telegram bot**: fitur "📡 Online Sekarang" baru di menu utama —
  sebelumnya fitur ini cuma ada di web, sekarang bot juga bisa nampilin
  daftar akun online + total device + lokasi/ISP tiap akun.

#### ✨ Added — Custom nama akun di web dashboard & Telegram bot
Ketemu pas user nanya kenapa akun bikinan CLI (`menu/m-vmess.sh` dkk,
lewat SSH) bisa custom nama (`rizal`, `andrew`, dst) tapi akun bikinan
web/bot (`TOOLS/bot/account.sh`) selalu random (`Vmess-XXXXX`) —
ternyata emang dua implementasi "create account" yang beda, gak
pernah disamain.
- `account.sh create` sekarang terima argumen ke-6 (nama) opsional.
  Kosong = tetap random kayak sebelumnya. Diisi = validasi format
  (`^[a-zA-Z0-9_.-]+$`, sama persis kayak validasi di CLI asli) +
  cek duplikat (`USER_EXISTS` kalau nama udah dipakai).
- **Web dashboard**: modal "Buat Akun Baru" nambah field teks nama
  (placeholder "kosongin = random").
- **Telegram bot**: setelah pilih limit IP, muncul pilihan "🎲 Random"
  atau "✏️ Custom Nama" sebelum akun dibuat.

#### ✨ Added — Lokasi/ISP per-akun (Online Now & Info Akun)
- `TOOLS/bot/lib-ipinfo.sh` baru: helper `ipinfo_lookup()` bareng,
  dipakai `online.sh` dan `account.sh` (action `info`), dengan cache
  on-disk per-IP (TTL 1 jam) biar gak boros kuota lookup ipinfo.io.
- **Online Now** (web dashboard) sekarang nunjukin Lokasi/ISP dari IP
  terakhir tiap user yang aktif.
- **Info Akun** (web + Telegram bot) nambah baris Last IP + Lokasi/ISP
  dari aktivitas terakhir akun itu.

#### 🐛 Fixed — JSON rusak & cache ipinfo numpuk tanpa batas
- Nama ISP yang punya tanda kutip di dalamnya (institusi Rusia,
  contoh `Federal State Institution ... "Peoples Friendship
  University..."`) bikin regex ekstraksi city/org di
  `lib-ipinfo.sh` berhenti di tengah dan JSON output `online.sh`
  jadi invalid — akibatnya dashboard "Online Sekarang" keliatan
  kosong padahal ada user aktif. Diperbaiki regex-nya (handle
  escaped quote) + ditambah JSON-escaping sebelum di-embed.
- Cache `lib-ipinfo.sh` sebelumnya cuma dedupe per-IP, nggak pernah
  expire entry lama — bisa numpuk selamanya karena CGNAT bikin 1
  device ganti-ganti IP terus. Sekarang di-prune otomatis (buang
  entry yang lebih tua dari TTL) tiap kali nulis cache.
- `online.sh` kadang nangkep teks sampah (misal literal `"tcp"`)
  sebagai `last_ip` kalau format baris access.log beda dari biasanya
  — field itu belum divalidasi formatnya kayak `ip_count` yang udah
  ada validasi IPv4. Ditambahin validasi yang sama.

#### 🐛 Fixed — RAM numpuk/habis dari CLI menu (bash process leak)
Ketemu pas RAM VPS keliatan naik terus tanpa henti: hampir **5000
proses `/bin/bash` numpuk** dalam 1 sesi SSH yang dibiarkan kebuka
15+ jam, makan ~2.3GB RAM + bikin swap ke-pakai.
- Akar masalah: tiap kali pencet "0" (balik ke menu) atau salah input
  di hampir SEMUA script menu (`menu.sh`, `sshws.sh`, `m-vmess.sh`,
  `m-vless.sh`, `m-trojan.sh`, `menu-backup.sh`, `m-theme.sh`,
  `cekservice.sh`, `system.sh`), script manggil nama binary-nya
  sendiri (misal `menu`) sebagai proses anak baru, bukan ganti proses
  yang jalan sekarang — proses lama nunggu (`wait`) proses baru
  selesai, jadi nggak pernah keluar selama sesi SSH itu masih hidup.
  Makin lama dipakai (makin sering gonta-ganti menu), makin numpuk.
- Fix: semua pemanggilan diri sendiri itu diganti pakai `exec`, jadi
  proses diganti di tempat (PID sama) bukan nested baru — nggak ada
  lagi akumulasi.
- Karena file-file ini ditarik installer langsung dari repo pas
  install (`SYSTEM/ssh-vpn.sh`/`set-br.sh` → `wget` dari
  `menu/*.sh`), install VPS baru otomatis kebawa fix ini.
- Proses numpuk yang udah ada di VPS production ini langsung
  dibersihkan manual (`pkill`), RAM balik dari 2669MB → 383MB
  terpakai, swap dari 143MB → 3MB. Service inti (xray, nginx, bot,
  webapi, fail2ban, dropbear) gak terganggu sama sekali.

#### ✨ Added — Lokasi/ISP server pakai token ipinfo.io asli
- `menu/menu.sh` punya baris `IPINFO_TOKEN` yang tadinya cuma placeholder
  contoh (`"Abc12345"`) — diganti token asli (daftar gratis di
  ipinfo.io) biar info lokasi/ISP VPS di menu CLI nampil akurat, bukan
  gagal diam-diam.
- Info lokasi/ISP yang sama diteruskan ke **web dashboard** dan **bot
  Telegram**, lewat `TOOLS/bot/status.sh` (sumber data bareng buat bot
  & webapi) — `status.sh` baca token itu langsung dari `/usr/bin/menu`
  (gak duplikat token di file lain), query `ipinfo.io`, keluarin field
  `CITY`/`ISP`. Dashboard nampilin kartu "Lokasi / ISP" baru (muncul
  cuma kalau datanya ada), status Telegram nambah baris `📍 Lokasi`.

#### ⚠️ Dicoba lalu di-revert — IP-limit active blocking
Sempat dicoba upgrade `iplimit-daemon.py` dari notify-only jadi **aktif
blokir** IP yang kelebihan limit (pakai `ipset`, auto-expire 10 menit,
O(1), + safety-check CGNAT — skip blokir kalau IP dipakai bareng akun
lain). Di-**revert total ke notify-only** di hari yang sama setelah
kejadian nyata:
- Percobaan pertama (hitung per-IP exact) salah blokir 2 device asli
  admin sendiri — provider mobile Indonesia rotasi IP publik tiap
  beberapa menit walau device-nya sama (1 HP → 15 IP beda dalam 5
  menit, lewat 2 blok `/16`).
- Percobaan kedua (grouping per-subnet `/16`, match persis sama data
  insiden pertama) **masih bug** — begitu user kelebihan limit, tiap
  baris log baru dari subnet yang sama tetap re-trigger blokir ke IP
  exact yang berbeda-beda, jadi tetap numpuk banyak blokir.
- Riset: Xray-core **gak punya** fitur native `limitIp` per-client
  (field itu cuma kosmetik di beberapa panel kayak 3x-ui, gak beneran
  di-enforce oleh core — maintainer Xray nolak nambahin business logic
  kayak gini ke core). Bahkan panel established (Marzban, via project
  `v2iplimit`) pakai pendekatan sama — scraping log — dengan kelemahan
  fundamental sama: IP itu proxy yang gak reliable buat "device" kalau
  jaringan antara klien-server gak stabil.
- Kesimpulan: fitur blocking balik ke **notify-only** permanen (lihat
  entri "Realtime IP-limit" di bawah) — admin dikasih tau, keputusan
  lanjut (manual) ada di tangan admin, bukan otomatis.

#### ✨ Added (lanjutan — Realtime IP-limit, Custom input, Trial lengkap)
- **Deteksi multi-login jadi realtime** — sebelumnya `iplimit-check.sh`
  jalan via cron tiap 2 menit (polling). Diganti `iplimit-daemon.py`,
  jalan sebagai systemd service, nge-`tail -f` `access.log` xray secara
  terus-menerus (bukan baca ulang 3000 baris tiap siklus) — begitu ada
  baris baru masuk, langsung dicek saat itu juga. Delay turun dari
  maks ~2 menit ke ~1 detik. Tahan logrotate (`copytruncate` maupun
  rename-based rotation, deteksi lewat inode+size). Tetap notif-only,
  cooldown 10 menit per user, refresh daftar user+limit dari
  `config.json` tiap 60 detik (nangkep akun baru/limit yang diubah).
- **Custom input** buat durasi/quota/limit IP pas "Buat Akun Full" — di
  web ada opsi "Custom..." di dropdown yang munculin input number; di
  Telegram ada tombol "✏️ Custom" yang minta ketik angka langsung di
  chat (state di-track per chat_id in-memory).
- **Trial juga nunjukin semua varian link** — sebelumnya trial VMess/
  VLess cuma kasih 2 link (TLS/NTLS). Disamain sama Info Akun: 5 varian
  (TLS/NTLS/gRPC/HTTPUpgrade/XHTTP) buat VMess & VLess, 2 varian
  (WS/gRPC) buat Trojan.
- **Modal CSS ganti native `prompt()`** — Renew & Atur Limit Akun di web
  panel sebelumnya pakai `prompt()` bawaan browser (gak match tema).
  Sekarang modal sendiri dengan dropdown, konsisten sama modal lain.

#### ✨ Added (lanjutan — Info lengkap & Atur Limit)
- **Info Akun nunjukin semua varian link** — sebelumnya "Cek Akun"/"Buat
  Akun" di bot & web cuma kasih 1 link (WS doang). Sekarang `account.sh`
  generate semua varian yang beneran dikonfigurasi: VMess & VLess →
  TLS(WS)/NTLS(WS)/gRPC/HTTPUpgrade/XHTTP (5 link), Trojan → WS/gRPC
  (2 link, emang cuma segitu yang ke-inbound-kan). Ditampilin lengkap di
  Telegram & web panel.
- **Atur Limit Akun** (quota + limit IP/device) buat akun yang **udah
  ada** — sebelumnya limit cuma bisa diset pas create. Sekarang ada
  action baru `account.sh limit <proto> <user> <quota_gb> <iplim>`,
  tombol "⚙️ Atur Limit Akun" di bot (pilih protokol → user → quota →
  IP limit) dan tombol "Limit" di tabel Akun web panel.

Ditemukan & dibenerin pas tes instalasi beneran ke VPS (bukan cuma baca kode) —
bug-bug ini independen dari perbaikan memory-leak kemarin:

#### 🐛 Fixed
- **`SYSTEM/ssh-vpn.sh`** — `apt install` dipanggil SEBELUM `apt update`,
  bikin banyak paket ("jq", "bzip2", "vnstat", dll) gagal "Unable to locate
  package" di VPS fresh yang cache APT-nya belum pernah di-refresh.
  Ditambah `apt update -y` di paling awal script.
- **`SYSTEM/ssh-vpn.sh`** — dropbear cuma di-config, **gak pernah
  di-`apt install`** — service dropbear gak akan pernah aktif karena
  paketnya emang gak ada. Ditambah `apt -y install dropbear`.
- **`SYSTEM/ssh-vpn.sh`** — fail2ban ke-install tapi gak pernah
  di-`enable`/`start`. Ditambah `systemctl enable --now fail2ban`.
- **`SYSTEM/ssh-vpn.sh`** — `sed` buat nambah `Port 200` nyari teks
  "Port 22", tapi default Ubuntu nge-comment baris itu (`#Port 22`) — sed
  gak match ke baris yang di-comment, port 22 default jadi gak pernah aktif
  eksplisit begitu ada `Port` directive lain. Diperbaiki jadi idempotent
  (uncomment dulu, cek belum ada sebelum nambah, gak dobel kalau script
  kejalanin lebih dari sekali).
- **`SYSTEM/ins-xray.sh`** — baris install Xray-core pakai flag `-u
  www-data` yang **udah di-drop** sama installer resmi XTLS
  (`install-release.sh`) — bikin instalasi binary Xray **gagal diam-diam**
  (karena gak ada `set -e`, sisa script tetap jalan & "sukses" walau xray
  gak pernah kepasang). Flag `-u` dihapus dari pemanggilan.

#### 🔒 Security
- **`SYSTEM/issue.net`** — banner login SSH/dropbear masih branding
  "HOKAGE LEGEND" + nomor WhatsApp pihak ketiga, muncul ke SETIAP orang
  yang login SSH ke VPS kamu. Dinetralkan jadi generik.

#### ✨ Added — BlackMagic VPN Telegram Bot (`TOOLS/bot/`)
Fitur bot Telegram baru biar bisa kelola VPS tanpa SSH, full tombol
(gak perlu ngetik command). Dibangun dari nol (source bot lama dari
upstream "HOKAGE LEGEND" udah gak ada di manapun, termasuk repo
aslinya) — murni Python stdlib (long-polling, no dependency), jalan
sebagai systemd service `blackmagic-bot.service`.
- **Status Server** — RAM/CPU/uptime/disk + status xray/nginx/dropbear/
  fail2ban/ws-stunnel.
- **Akun Aktif** — list semua akun VMess/VLess/Trojan, diurut dari yang
  paling cepat expired, dipagingkan (15/halaman) biar gak overflow kalau
  akunnya ratusan.
- **Trial VMess/VLess/Trojan** — bikin akun trial, pilih durasi via tombol
  (5/60/1440 menit).
- **Buat Akun Full** — pilih protokol → durasi (7/30/90 hari) → quota
  (unlimited/50/100GB) → limit IP (1/2/unlimited), semua via tombol.
- **Cek Akun & Hapus Akun** — list user per protokol (dipagingkan,
  10/halaman, diurut sama kayak Akun Aktif) → pilih → tampil detail/hapus.
- **Server Tools** — Cek Port, Restart Semua Layanan, Reboot VPS (pakai
  konfirmasi), dan **Atur Backup** (toggle jadwal auto-backup
  harian/mingguan/off, nulis langsung ke `/etc/cron.d/blackmagic-autobackup`).
- **Backup Sekarang** — jalanin `/usr/bin/backup` on-demand (zip config →
  upload Google Drive via `rclone` → kirim link + file ke chat yang sama).
- **Auto-backup cron** — default jam 03:00 WIB tiap hari, log ke
  `/var/log/blackmagic-autobackup.log`.
- **Expiry notif H-3** (`expiry-check.sh`, cron jam 09:00 WIB) — scan semua
  akun + license VPS, kirim warning Telegram buat yang exp pas 3 hari lagi.
- **Crash alert** — `xray.service` & `nginx.service` dikasih drop-in
  `OnFailure=blackmagic-alert@%n.service` (template unit baru) + nginx
  ditambah `Restart=on-failure` (sebelumnya gak ada sama sekali) — begitu
  systemd auto-restart service yang crash, admin langsung kebagian notif
  Telegram.
- Hanya admin yang ID chat-nya ada di `/etc/xray/bot_admins` yang bisa
  pakai bot (chat lain otomatis ditolak).
- `menu/admin` opsi `[1] Install Bot` diperbaiki — sebelumnya `wget` ke
  repo `Telegram-bot` yang gak pernah ada (baik di akun sendiri maupun
  akun upstream), sekarang instalasi interaktif asli: minta Bot Token,
  auto-detect Chat ID via `getUpdates`, tarik file dari
  `TOOLS/bot/` di repo ini sendiri.
- **Renew Akun** di bot — perpanjang expired akun VMess/VLess/Trojan yang
  udah ada (pilih protokol → pilih user → tambah 7/30/90 hari), gap yang
  sebelumnya belum ke-cover (cuma ada create/delete/info).
- **Dashboard monitoring** (`TOOLS/bot/dashboard/`) — halaman statis
  HTML+JS ringan (gak ada backend app server, data di-generate cron tiap
  menit ke `data.json` lewat `dashboard-gen.sh`) buat liat RAM/CPU/disk/
  uptime, status semua service, dan jumlah akun per protokol secara
  visual. Di-serve nginx di path `/dashboard/` lewat domain+TLS yang udah
  ada (reuse, gak buka port baru), dilindungi HTTP Basic Auth
  (`/etc/nginx/.htpasswd-dashboard`) — jadi gak perlu connect VPN/SSH
  tunnel buat ngelihatnya, cukup buka browser & login.
- **Web control panel full fitur** (`TOOLS/bot/webapi.py` +
  `TOOLS/bot/dashboard/index.html`) — dashboard di atas diupgrade jadi
  panel lengkap dengan sidebar kiri (Dashboard, Akun, Trial, Backup,
  Server Tools), fitur 1:1 sama kayak bot Telegram: buat/renew/hapus/cek
  akun (dengan modal & tabel per protokol), trial, backup manual + atur
  jadwal, restart layanan, reboot VPS. Frontend pakai **Tailwind CSS**
  (CDN, dark theme) — vanilla JS, gak ada build step. Backend
  `webapi.py` murni Python stdlib (`http.server`, bukan Flask/Django),
  listen di `127.0.0.1:8099` doang (gak exposed langsung), dipanggil
  lewat proxy nginx di `/dashboard/api/` yang udah ditambah basic auth
  yang sama. Jalan sebagai systemd service `blackmagic-webapi.service`
  terpisah dari bot Telegram, tapi keduanya share script yang sama
  (`account.sh`, `trial-*.sh`, dst) jadi perilakunya konsisten di dua
  antarmuka.
- **Chart RAM/CPU + bar chart akun** di web panel Dashboard — line chart 2
  jam terakhir (sample tiap menit via cron, disimpan di `history.json`,
  rolling ~120 titik) dan bar chart jumlah akun per protokol. Warna chart
  (`#3987e5` / `#199e70`) divalidasi pakai `dataviz` skill's
  `validate_palette.js` buat mastiin CVD-safe, bukan asal pilih.
- **Pagination tabel Akun** di web panel — pilih 10/15/20 baris per
  halaman + tombol Prev/Next, konsisten sama urutan di bot (yang paling
  cepat expired duluan).
- **Redesign visual web panel** — ganti dari tema Tailwind dark generik
  (near-black + satu aksen biru, salah satu pola default yang gampang
  ketauan "AI-generated") jadi design system sendiri: palet graphite-teal
  + aksen ganda (teal-signal buat status live, electric blue buat aksi),
  tipografi Inter + JetBrains Mono, signature pulse-ring di satu titik
  (status sinyal), card hover-lift, modal backdrop-blur.
- **Logs viewer** (menu baru "Logs" di web panel, `TOOLS/bot/logs.sh`) —
  tail 5 file log (Auto Backup, Expiry Warning, Expiry Enforce, Xray
  Access, Xray Error) + `journalctl` 4 service (Bot, Web API, Xray,
  Nginx) langsung dari browser, gak perlu SSH buat debug.
- **Online Sekarang** (panel baru di Dashboard, `TOOLS/bot/online.sh`) —
  nunjukin akun yang beneran aktif (traffic xray dalam 2 menit terakhir)
  + jumlah IP berbeda yang dipakai, beda sama "Akun Aktif" yang cuma
  nunjukin status expired.
- **Notifikasi multi-login / limit device** (`TOOLS/bot/iplimit-check.sh`,
  cron tiap 2 menit) — bandingin jumlah IP berbeda per akun vs limit IP
  yang diset (`0`/`9999` = unlimited, `1`/`2`/`3` = jumlah device). Kalau
  lebih, kirim notif Telegram (dengan cooldown 10 menit biar gak spam) —
  **notif doang, akun gak diubah/dihapus otomatis** (keputusan sengaja,
  biar admin yang nentuin tindakan lanjut).

#### 🐛 Fixed
- **Xray gak bisa baca IP klien asli** — semua koneksi vmess/vless/trojan
  lewat proxy nginx lokal (`127.0.0.1`), jadi `access.log` cuma nyatet
  `127.0.0.1` buat semua orang, bikin fitur "Online"/limit-IP gak bisa
  bedain device. Diperbaiki dengan nambah
  `"sockopt": {"trustedXForwardedFor": ["X-Forwarded-For"]}` di tiap
  inbound WS/gRPC/HTTPUpgrade/XHTTP (`/etc/xray/config.json` di VPS +
  template `SYSTEM/ins-xray.sh` buat instalasi baru) — xray versi
  26.10.17 butuh nama header di list ini, BUKAN daftar IP/CIDR kayak
  dokumentasi versi lama (sempat salah coba pakai `["127.0.0.1/32"]`
  dulu, malah muncul error baru "ignored potentially forged
  X-Forwarded-For" — ke-revert dulu sebelum ketemu format yang benar).
  Setelah fix, `access.log` nunjukin IP publik asli, bukan `127.0.0.1`
  lagi. Aman karena semua inbound xray cuma `listen: 127.0.0.1` (dicek
  ke-13 inbound-nya) — satu-satunya yang bisa ngirim header itu ya nginx
  di localhost yang sama, gak ada attack surface spoofing dari luar.
- **Akun expired masih bisa dipakai sampai ~24 jam** — script pembersih
  akun expired asli (`/usr/bin/xp`) cuma jalan sekali sehari jam 00:00
  (`/etc/cron.d/xp_otm`), jadi akun yang expired siang/sore tetap aktif
  sampai tengah malam berikutnya. Gak bisa sekadar naikin frekuensi cron
  `xp` yang asli karena dia restart Xray 3x tanpa cek dulu ada perubahan
  atau tidak — kalau dijalanin tiap 5 menit bakal restart Xray terus-
  terusan 24/7 dan motong semua koneksi aktif berulang. Solusinya:
  `TOOLS/bot/expiry-enforce.sh` baru, cron tiap 5 menit, cuma restart
  Xray kalau beneran ada akun yang dihapus di run itu. Langsung ketahuan
  jalan pas pertama diaktifkan — ketemu & hapus 1 akun trial VMess yang
  udah expired tapi masih nyangkut di config.

### [2026-10-19]

#### 🐛 Fixed
- **`TOOLS/limit-ip`** — proses `vmip`/`vlip`/`trip` dulu gak punya loop
  internal, jadi di-restart sistem tanpa henti (respawn-storm) tiap kali
  selesai jalan sekali. Ini akar utama RAM/CPU naik terus pas banyak user
  online bersamaan. Dibungkus `while true; sleep 10; done` sendiri.
- **`menu/xraylimit.sh`, `menu/tendang.sh`** — jadwal otomatis (cron) tiap
  1 menit bisa numpuk jalan bareng (overlap) kalau proses sebelumnya belum
  selesai, dan baca SELURUH file log tiap kali jalan. Ditambah penanda
  anti-tumpuk (`flock`) + baca log cuma 20.000 baris terakhir.
- **`SYSTEM/xp.sh`** — restart Xray 3x berturut-turut dalam 1x jalan
  (jadwal harian), bisa putus koneksi semua user berkali-kali. Disisakan
  1x restart di akhir.
- **`menu/xraylimit.sh`** — jadwal "kunci user login ganda" yang dibuat
  otomatis gak pernah hapus diri sendiri, numpuk selamanya. Sekarang
  self-delete setelah jalan sekali.
- **`SYSTEM/proxy3.js`** — "pembersihan memori" paksa tiap 1 detik (gak
  nyelesain leak aslinya, nambah beban CPU) dan listener kode mati
  dihapus; ditambah batas maksimal 2000 koneksi bersamaan.
- **`SYSTEM/nginx.conf`** — cuma pakai 1 proses worker (1 inti CPU) buat
  semua trafik, jadi bottleneck pas rame. Diubah ke `auto` (pakai semua
  inti), kapasitas koneksi per worker dinaikkan 1024 → 4096.
- **`WEBSOCKET/ws-dropbear`, `ws-ovpn.py`, `ws-stunnel`** — bikin 1
  thread baru per koneksi tanpa batas. Ditambah batas maksimal 1500
  koneksi, koneksi lebih ditolak gak numpuk thread.
- **`menu/update.sh`** — URL download `trialvless.sh`/`trialtrojan.sh`
  ketuker (file `trialvless` malah isinya kode `trialtrojan`, dan
  sebaliknya). Dibenerin jadi masing-masing narik file yang bener.

#### ✨ Added
- **`SYSTEM/ins-xray.sh`** — tambah rule routing `geosite:category-ads-all`
  (ad-block resmi dari Xray-core) sebagai rule pertama di `config.json`,
  berlaku buat vmess/vless/trojan (semua protokol Xray). Belum berlaku
  buat SSH murni (gak lewat Xray). Lihat STEP 2.6.
- **`SYSTEM/xray-logrotate.conf`** — konfigurasi pembersihan log Xray
  otomatis (harian, simpan 3 hari terakhir, maksimal 100MB), auto-terpasang
  lewat `SYSTEM/ins-xray.sh` pas instalasi baru.
- **Validasi minimum waktu trial** di `menu/sshws.sh`, `menu/m-vmess.sh`,
  `menu/m-vless.sh`, `menu/m-trojan.sh` — input `0`/kosong/bukan angka
  sekarang dipaksa jadi default 5 menit, cegah jadwal otomatis rusak.
- **Sistem lisensi private sendiri** (GitHub Contents API + token) buat
  11 file menu — menggantikan ketergantungan ke repo lisensi publik milik
  pihak ketiga. Lihat STEP 4 di atas buat setup.
- **`/etc/xray/license.conf`** — file config terpisah di VPS buat nyimpen
  token lisensi (`GH_USER`/`GH_REPO`/`GH_TOKEN`), supaya gak ketimpa tiap
  kali `update.sh` di-refresh dari repo.

#### 🔒 Security
- **`rc-clone`, `SYSTEM/rclone.conf`** — hapus OAuth Client ID/Secret &
  access/refresh token Google Drive asli yang sempat ter-commit plaintext,
  diganti placeholder.
- **`SLOWDNS/installsl.sh`** — hapus Cloudflare Global API Key + email
  asli (milik pihak ketiga) yang ter-hardcode, diganti placeholder +
  domain jadi variabel (dulu hardcode ke domain pihak ketiga).
- Seluruh referensi domain/username pihak ketiga (127 titik di 13 file)
  diganti ke milik sendiri (`backupdatt`).
- Token lisensi gak lagi ditulis langsung di file yang ikut ter-update
  dari repo (lihat `/etc/xray/license.conf` di atas) — mencegah token
  bocor kalau repo `backupdatt/genom` sempat di-toggle Public.

#### ⚠️ Known Issues (belum diperbaiki, sengaja ditunda)
- `menu/update.sh` masih narik `/usr/bin/xp` dari `menu/xp`, bukan
  `SYSTEM/xp.sh` — kalau dijalankan, bisa nimpa balik fix #5 di atas.
  `update.sh` sengaja belum dirombak untuk saat ini.
