# Oturum kaydı

Bu proje tek gün (15 Ekim 2026) içinde, Claude uygulamasında rehberli oturumlarla yapıldı.

Token sayıları oturum kayıtlarından, saat aralıklarına göre sayıldı. Maliyet Claude Opus 5.5 liste fiyatıyla hesaplandı (girdi 4 $/MTok, çıktı 20 $/MTok; önbellekten okuma 0,1×, önbelleğe yazma 2× varsayıldı). Ödeme abonelikle yapıldı, ayrıca para ödenmedi.

| # | Saat | Ne yapıldı | Çıktı token | Önbellek okuma / yazma | ≈ Maliyet |
|---|---|---|---|---|---|
| 1 | 09:41–15:00 | Ders özeti, ödev planı, Faz 1–2 araştırması, kullanıcı yorumlarının toplanması, README/PLAN taslağı | ~41k | 6,7M / 0,31M | ~6 $ |
| 2 | 15:00–16:55 | Rails iskeleti, GitHub Actions CI, Render'a ilk deploy | ~61k | 36,4M / 0,46M | ~19 $ |
| 3 | 16:55–19:10 | Giriş, Ticket modeli ve durum makinesi, talep ekranları, SLA motoru, zaman kuralları, README | ~123k | 46,8M / 0,17M | ~23 $ |
| 4 | 19:10–20:00 | Arayüz yeniden tasarımı, test raporu (12 bulgu) ve düzeltmeleri, şifre sıfırlama denemesi | ~73k | 32,7M / 0,12M | ~16 $ |
| 5 | 20:00–23:45 | Demo verisi, müşteri sayfası (gizli link), canlıda uçtan uca test, iki dış inceleme turunun düzeltmeleri | ~113k | 42,4M / 0,27M | ~21 $ |
| | **Toplam** | | **~410k** | **~165M / ~1,3M** | **~85 $** |

## Karşılaşılan sorunlar ve çözümleri

### Oturum 2: Windows + CI + Render
| Sorun | Neden | Çözüm |
|---|---|---|
| `rails new` sonrası Bootsnap `ENOENT` hatası | Windows kullanıcı yolunda "ü" ve boşluk var (`Begüm Handan Demir`) | Bootsnap Windows'ta kapatıldı (`config/boot.rb`) |
| Kurulum sonrası üreteçler (importmap, turbo, stimulus, solid_*) çalışmadı | Aynı yol sorunu | Kurulum komutları tek tek elle çalıştırıldı |
| CI'da `bin/*` çalışmadı (exit 127) | Dosyalar Windows'ta çalıştırılabilir değildi ve ilk satırları `ruby.exe` idi | `git update-index --chmod=+x`; ilk satır `ruby` yapıldı |
| CI hiç tetiklenmedi | İş akışı `master` dalını dinliyordu | `main` yapıldı; runner `ubuntu-24.04`'e sabitlendi |
| CI'da şema bulunamadı / system-test hatası | `schema.rb` yoktu; tarayıcı testi yazmıyoruz | `db:migrate` ile şema üretildi; system-test işi kaldırıldı |
| Render deploy'u: "The `cache` database is not configured" | Rails 8 varsayılanı ayrı bir cache veritabanı istiyor, ücretsiz planda tek veritabanı var | `cache.yml`'den ayrı veritabanı kaldırıldı, `memory_store` kullanıldı |
| Render deploy'u "failed" | Ana sayfa yokken sağlık kontrolü `/` 404 alıyordu | Health Check Path `/up` yapıldı |
| Ruby 4.0.7'nin Render'ın Ruby ortamındaki desteği belirsiz | — | Render'da Docker (Rails'in kendi Dockerfile'ı) kullanıldı |

### Oturum 3–5: Uygulama
| Sorun | Çözüm |
|---|---|
| Testler paralel çalışınca SQLite "database is locked" | `parallelize(workers: 1)` |
| Kapalı talebe yanıt yazılabiliyordu; ilk yanıttan sonra SLA yeniden hesaplanıyordu | Kapalı talep koruması ve "ilk yanıt verildiyse son tarih sabit" kuralı, testleriyle |
| Şifre sıfırlama e-postası gitmedi | Render ücretsiz planı SMTP portlarını kapatıyor → Resend HTTPS API'si yazıldı, ama Resend canlı anahtarı reddetti (401). Özellik kapatıldı, README'de "Yapamadıklarım"a yazıldı |
| Müşteri yanıtları görmüyordu ("var deyip çalışmayan" riski) | Gizli linkli müşteri sayfası eklendi |
| Yasak geçişlerin yarısının testi yoktu | Testler `TRANSITIONS` tablosundan otomatik üretiliyor (21/21) |
| Beklemedeyken yanıt verilip açılan talepte son tarih boş kalıyordu | `transition_to!` düzeltildi, testi eklendi |
| Arayüz "sizden yanıt beklerken sayaç durur" diyordu, ama durmuyordu | Metin düzeltildi: yalnızca 3. taraf beklenirken durur |
| Müşteri sayfasından yanıt gönderilemiyordu (canlıda 422) | Gizlilik için konan `Referrer-Policy: no-referrer` tarayıcının `Origin: null` göndermesine, Rails CSRF kontrolünün de isteği reddetmesine yol açıyordu. Testler CSRF kapalı çalıştığı için yakalamadı. Politika `same-origin` yapıldı; CSRF açıkken çalışan bir test eklendi |
