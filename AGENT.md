# AGENT.md — SLA Clock

Bu dosya, bu projede çalışan kodlama ajanı (ve insan geliştirici) için ortak sözlük ve kurallardır.
Ajan her oturumda önce bu dosyayı okur. Kural değişirse önce bu dosya güncellenir.

## 1. Ürün tek cümlede

Destek ekipleri için talep yönetimi: talep gelir → atanır → yanıtlanır → çözülür; ilk yanıt SLA'sı
ekibin iş takvimine (mesai, tatil, saat dilimi) göre hesaplanır ve neden o saatte dolduğunu açıklar.

## 2. Domain sözlüğü (TR ↔ EN)

| Türkçe | Kodda | Not |
|---|---|---|
| Talep | `Ticket` | |
| Talep sahibi / müşteri | `requester_email` | Giriş yapmaz |
| Temsilci | `User` | Giriş yapar |
| Atanan temsilci | `assignee` | `User`'a referans |
| Yanıt | `Comment` | Temsilci yanıtı |
| İç not | `Comment` (`internal: true`) | Müşteri görmez, ilk yanıt sayılmaz |
| İlk yanıt | `first_responded_at` | İlk herkese açık temsilci yanıtı |
| Öncelik | `priority`: low, normal, high, urgent | |
| Durum | `status`: new, open, pending, on_hold, solved, closed | |
| Müşteri bekleniyor | `pending` | |
| Üçüncü taraf bekleniyor | `on_hold` | SLA sayacı durur |
| SLA ihlali | `overdue` / `sla_breached?` | |
| İlk yanıt süresi | `first_response_due_at` | |
| İş takvimi | `BusinessCalendar` | Mesai, hafta sonu, tatil |
| Resmi tatil | `Holiday` | |

## 3. Durum akışı

```
new ──▶ open ──▶ pending ──▶ open
          │──▶ on_hold ──▶ open
          └──▶ solved ──▶ closed
solved ──(müşteri yanıtı)──▶ open
```

- Geçişler YALNIZCA `Ticket#transition_to!(yeni_durum)` üzerinden yapılır.
  Kural dışı geçiş `Ticket::InvalidTransition` fırlatır.
- `enum` bang metotları (`solved!` vb.) kullanılmaz; enum `instance_methods: false` ile tanımlıdır.
- Her yasak geçişin bir testi vardır.

## 4. Yasak sihirler

- `default_scope` — yasak. Adlandırılmış `scope` kullan.
- `method_missing`, global monkey patch — yasak.
- İş mantığı içeren callback (`before_save`, `after_commit` …) — yasak. İş kuralı açık metotta ya da
  `app/services/` altında bir serviste olur. Callback yalnızca türetilmiş alan için kullanılabilir.
- Concern kullanılırsa adı davranışını anlatmalı ve buraya yazılmalı.

## 5. Test kuralları

- Her zaman kuralının `travel_to` ile testi vardır.
- Her yasak durum geçişinin testi vardır.
- "Testler geçti" demek için GitHub Actions'ın yeşil olması şarttır. Ajanın kendi raporu kanıt değildir.

## 6. Kural haritası (kod yeri sorusu için)

| Kural | Dosya |
|---|---|
| Durum geçişleri | `app/models/ticket.rb` (`TRANSITIONS`) |
| Atama yeni talebi açar | `app/models/ticket.rb` (`assign_to!`) |
| İlk yanıt ne sayılır? | `app/models/ticket.rb` (`add_reply!`) |
| _(SLA, takvim, job'lar eklendikçe doldurulacak)_ | |

## 7. Konvansiyondan sapmalar (neden?)

| Sapma | Nerede | Neden |
|---|---|---|
| Bootsnap Windows'ta kapalı | `config/boot.rb` | Windows kullanıcı yolundaki ü/boşluk Bootsnap'in dosya açmasını bozuyor |
| `bin/*` ilk satırı `ruby` (`ruby.exe` değil) | `bin/` | Proje Windows'ta oluşturuldu; Linux CI'da `ruby.exe` yok |
| CI `ubuntu-24.04`'e sabit | `.github/workflows/ci.yml` | `ubuntu-latest` 19 Ekim 2026'da Ubuntu 26'ya geçiyor (teslim günü) |
| CI'da `system-test` yok | `.github/workflows/ci.yml` | Tarayıcı testi yazmıyoruz; model/entegrasyon testleri yeterli |
| Geliştirme/test SQLite, canlı PostgreSQL | `Gemfile`, `config/database.yml` | Render ücretsiz planında kalıcı disk yok |
| Canlıda önbellek `memory_store`, Cable `async` | `production.rb`, `cable.yml`, `cache.yml` | Ücretsiz planda tek veritabanı var |
| Canlıda Active Job `async` (geçici) | `production.rb` | Solid Queue zaman kuralı job'larında tek veritabanıyla kurulacak |
| Deploy Render'da Docker ile | `Dockerfile` | Render'ın Ruby ortamında Ruby 4.0.7 desteği belirsizdi |
| Render Health Check Path = `/up` | Render ayarı | Ana sayfa yokken `/` 404 dönüyor ve deploy başarısız sayılıyordu |

## 8. Çalıştırma (Windows)

```powershell
ruby bin/rails server      # http://localhost:3000
ruby bin/rails test        # testler
ruby bin/rubocop           # stil
```
