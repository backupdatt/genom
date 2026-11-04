# Changelog

Format ikut [Keep a Changelog](https://keepachangelog.com/).

### [2026-11-04]

#### 🔒 Security — Xray update ke 26.10.31 (MPTCP dimatiin default)
Kernel Linux ketauan ada bug di IPv4 MPTCP yang bikin remote root jadi gampang, dan Go 1.24+ (bahasa xray-core) ngaktifin MPTCP by default — versi ini matiin MPTCP buat ngurangin attack surface. Update lewat installer resmi, semua 78 akun diverifikasi tetep utuh dan handshake WS tetep jalan normal setelahnya.

#### ✨ Added — Varian link baru: VLESS+REALITY+XHTTP (port 2096)
Nambah 1 varian koneksi baru di samping TLS/NTLS/gRPC/HTTPUpgrade/XHTTP yang udah ada: REALITY (kamuflase TLS, nyamar jadi `www.microsoft.com`) dibungkus XHTTP transport, listen langsung di port 2096 (belum lewat nginx/443). Dites dulu manual pakai akun terpisah sebelum di-backfill ke semua akun vless yang ada dan diotomatisin di `account.sh` (create/restore/delete) + ditambahin ke daftar link di bot Telegram & dashboard.

#### 🐛 Fixed — HTTPUpgrade & XHTTP (vless) drift dari `account.sh`
Ketauan pas nambah REALITY: `account.sh` ternyata cuma pernah sync ke 2 dari 4 inbound vless (WS & gRPC), jadi 8 akun gak pernah kebagian entry di inbound HTTPUpgrade/XHTTP-nya — link itu kemungkinan gak connect buat mereka. 8 akun itu di-backfill manual, dan `account.sh` (create/restore/delete) sekarang sync ke semua 5 inbound vless sekaligus biar gak drift lagi.

### [2026-10-25]

#### 🔒 Security — Xray kepasang versi yang ditarik XTLS, update ke stable
Versi xray di VPS (`26.10.17`) ternyata udah ditarik XTLS karena ikut percaya sertifikat yang private key-nya kebobol; `SYSTEM/ins-xray.sh` juga ketauan ambil versi dari endpoint GitHub yang gak dijamin stable, sekarang difix. Pas update ke `26.10.21`, ketemu bug installer resmi yang reset path config xray ke lokasi kosong (langsung diperbaiki + dibikin otomatis-kefix di script biar gak kejadian lagi).

#### ✨ Added — Restore akun expired (CLI, Telegram bot, web dashboard)
Dulu akun expired langsung dihapus permanen tanpa jalan balik, ketauan masalahnya pas 1 akun customer kehapus gak sengaja. Sekarang `expiry-enforce.sh` arsipkan dulu selama 7 hari sebelum beneran dihapus, dan bisa di-restore pakai UUID yang sama lewat CLI, bot Telegram, atau dashboard web.

#### 🐛 Fixed — Traceback panjang di log webapi gara-gara klien disconnect
Klien yang nutup koneksi di tengah request bikin traceback 20-baris nongol di log, padahal itu perilaku normal bukan bug. Sekarang dibungkus jadi 1 baris log yang jelas.

#### ✨ Added — Ad-block diperluas: blokir domain telemetry/tracking juga
`category-ads-all` yang udah ada cuma nutup domain iklan; ditambah `geosite:category-ads-and-telemetry` di rule yang sama biar domain tracking/analytics (Google Analytics, dst) ikut keblokir. Otomatis berlaku ke semua akun vmess/vless/trojan yang ada (bukan per-akun), diverifikasi lewat simulasi client asli: domain normal tetap lolos, domain tracker (`google-analytics.com`) kebukti keblokir.

#### 🐛 Fixed — `menu/update.sh` nimpa balik fix "restart Xray 3x" yang udah ditunda dari 20 Oktober
Known issue lama yang sengaja ditunda akhirnya dibenerin: `update.sh` ternyata masih narik `/usr/bin/xp` dari `menu/xp` (versi lama, 3x restart), bukan `SYSTEM/xp.sh`. Dicek di server sendiri — ketauan `/usr/bin/xp` kita emang udah ketimpa balik jadi versi 3x restart (jalan tiap tengah malam via cron), langsung dibenerin manual + source URL di `update.sh` diganti ke `SYSTEM/xp.sh`, dan `menu/xp` (file lama) dihapus dari repo karena udah gak dipakai sama sekali.

### [2026-10-24]

#### ⚠️ Dicoba lalu di-revert — Proxy front-door + full-proxy egress buat anti-block Netflix
Dicoba bikin server kedua jadi "proxy" depan (TLS passthrough via nginx `stream`) + tunnel WireGuard biar semua traffic VPN keluar lewat IP proxy itu, tujuannya biar Netflix gak ngedeteksi IP server utama. Ternyata gak nolong — dua-duanya IP hosting/datacenter yang sama (Netflix blok berdasar ASN, bukan domain/SNI), jadi di-**revert total** (nginx, WireGuard, netplan, kode `_VIA_PROXY` di `account.sh`/`bot.py`/dashboard) balik ke kondisi semula.

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
