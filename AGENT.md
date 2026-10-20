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
| İş takvimi | `BusinessCalendar` | Pzt–Cuma 09:00–18:00, Europe/Istanbul |
| SLA hedefi | `SlaPolicy` | Önceliğe göre iş dakikası |
| SLA hesabı | `SlaClock` (servis) | Tek doğru kaynak; panel de buradan |
| SLA duraklatması | `SlaPause` | on_hold aralıkları |
| Resmi tatil | `Holiday` | |

## 3. Durum akışı

```
new ──▶ open ──▶ pending ──▶ open
          │──▶ on_hold ──▶ open
          └──▶ solved ──▶ closed
pending / solved ──(müşteri yanıtı, gizli linkten)──▶ open
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
  - `Authentication` (`app/controllers/concerns/authentication.rb`): Rails 8 kimlik doğrulama üretecinden gelir; temsilci girişini zorunlu kılar, `allow_unauthenticated_access` ile açılan sayfalar (talep formu, müşteri sayfası, giriş) hariç.

## 5. Test kuralları

- Her zaman kuralının `travel_to` ile testi vardır (`test/models/ticket_sla_test.rb`).
- Her yasak durum geçişinin testi vardır.
- "Testler geçti" demek için GitHub Actions'ın yeşil olması şarttır. Ajanın kendi raporu kanıt değildir.

## 6. Kural haritası (kod yeri sorusu için)

| Kural | Dosya |
|---|---|
| Durum geçişleri | `app/models/ticket.rb` (`TRANSITIONS`) |
| Atama yeni talebi açar | `app/models/ticket.rb` (`assign_to!`) |
| İlk yanıt ne sayılır? | `app/models/ticket.rb` (`add_reply!`) |
| "SLA hafta sonunu saymasın" / "Cumartesi çalışıyoruz" | `app/models/business_calendar.rb` (`WORK_DAYS`) |
| "Mesai 08:30'da başlasın" | `app/models/business_calendar.rb` (`WORK_START`, `WORK_END`) |
| "Acil talepte hedef 30 dk olsun" | `app/models/sla_policy.rb` (`FIRST_RESPONSE_MINUTES`) |
| "Bayramlar sayılmasın" | `db/seeds.rb` (`Holiday` kayıtları) |
| "on_hold SLA'yı durdurmasın" | `app/models/ticket.rb` (`transition_to!` içindeki `sla_pauses` satırları) |
| SLA hesabının kendisi | `app/services/sla_clock.rb` |
| "Pending 3 günde otomatik çözülsün" | `app/models/ticket.rb` (`PENDING_AUTO_SOLVE_AFTER`) |
| "Çözülen talep 2 günde kapansın" | `app/models/ticket.rb` (`SOLVED_AUTO_CLOSE_AFTER`) |
| Zaman kurallarını kim çalıştırır? | Canlıda `TicketsController#index` (temsilci listeyi açınca). `app/jobs/time_rules_job.rb` yazılı ama zamanlanmadı (Render ücretsiz planı uyuyor; bkz. README Yapamadıklarım) |
| Müşteri sayfası (gizli link `/t/:token`) | `app/controllers/customer_tickets_controller.rb`, `app/views/customer_tickets/show.html.erb` |
| "Müşteri yanıt verince talep açılmasın" | `app/models/ticket.rb` (`CUSTOMER_REPLY_REOPENS`, `add_customer_reply!`) |
| Müşteri hangi durum adlarını görür? | `app/helpers/customer_tickets_helper.rb` (`CUSTOMER_STATUS_LABELS`) |
| "Şu veri de maskelensin" (ör. adres, plaka) | `app/services/privacy_mask.rb` (`RULES`) |
| "Yaş aralığı 5 yıllık olsun" / yeni meslek grubu | `app/services/synthetic_persona.rb` (`AGE_BAND`, `FIELDS`) |
| Gerçek veriye kim baktı? | `app/models/pii_access_log.rb`, `TicketsController#reveal` |
| "Asistan daha temkinli olsun" | `app/services/ticket_triage.rb` (`MIN_CONFIDENCE`) |
| Asistan neye dayanarak yanıt verir? | `config/knowledge_base.yml` |
| "Teşekkür" yanıtı talebi açsın mı? | `app/services/reply_intent.rb` + `Ticket#add_customer_reply!` |
| Yapay zekâ akışı (triage → yanıt / devir) | `app/jobs/ai_triage_job.rb` |
| Ajan API'si | `app/controllers/api/v1/tickets_controller.rb`, belgesi `public/llms.txt` |

## 6b. Gizlilik ve yapay zekâ kuralları (2. hafta)

- **Temsilci ekranına ve LLM'e ham kişisel veri gitmez.** Her zaman `Ticket#agent_subject`, `#agent_body`,
  `Comment#agent_body` ya da `Ticket#privacy_mask.apply(...)` kullanılır. `subject`/`body`/`requester_email`
  temsilci görünümüne yalnızca `@revealed` (gerekçeli erişim, `PiiAccessLog`) varken basılır.
- Müşteriye kendi verisi gösterilir (`/t/:token`, ajan API'si); temsilcinin persona adıyla hitabı `unmask_for_customer` ile gerçek ada çevrilir.
- `LlmClient` dışında hiçbir yerden LLM çağrılmaz. Anahtar yoksa (`GROQ_API_KEY`) uygulama yapay zekâsız eski kurallarla çalışmalı.
- Asistan yalnızca `config/knowledge_base.yml`'deki bir maddeye dayanarak yanıt yazar; kaynak göstermiyorsa ya da emin değilse insana devreder.
- LLM kararları (aciliyet, niyet) anahtar kelime eşleştirmesiyle **taklit edilmez**. Kodda yalnızca güvenlik kontrolleri olur
  (kaynak var mı, güven eşiği, öncelik asla düşürülmez).
- Testlerde gerçek LLM çağrılmaz: `LlmClient.adapter = FakeLlm.new(...)`. Ham verinin LLM'e gitmediği `FakeLlm#all_prompts` ile test edilir.

## 6c. Deploy (Render) — ajan bunu buradan bilir

- Canlı: https://slaclock.onrender.com, Render ücretsiz plan, **Docker** (`Dockerfile`, Ruby 4.0.7).
- `main` dalına push → Render otomatik deploy eder. **Ajan push etmez; push'u kullanıcı yapar.** Ajan en fazla yerel commit atar.
- Açılışta `bin/docker-entrypoint`: `db:prepare` (migration'lar) + `db:seed`. Yeni migration ek adım istemez.
- Health check: `/up` (Render panelinde ayarlı).
- Ortam değişkenleri Render panelinde (repoda değil): `DATABASE_URL`, `RAILS_MASTER_KEY`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`,
  `DEMO_EMAIL`, `DEMO_PASSWORD`, `GROQ_API_KEY`, `GROQ_MODEL` (isteğe bağlı), `AGENT_API_TOKEN`.
  Ajan bu değerleri **asla** istemez, görmez, dosyaya yazmaz.
- `bin/render-build.sh` eski, kullanılmıyor (Docker'a geçmeden önceki Ruby ortamı için yazılmıştı).

## 7. Konvansiyondan sapmalar (neden?)

| Sapma | Nerede | Neden |
|---|---|---|
| Bootsnap Windows'ta kapalı | `config/boot.rb` | Windows kullanıcı yolundaki ü/boşluk Bootsnap'in dosya açmasını bozuyor |
| `bin/*` ilk satırı `ruby` (`ruby.exe` değil) | `bin/` | Proje Windows'ta oluşturuldu; Linux CI'da `ruby.exe` yok |
| CI `ubuntu-24.04`'e sabit | `.github/workflows/ci.yml` | `ubuntu-latest` 19 Ekim 2026'da Ubuntu 26'ya geçiyor (teslim günü) |
| CI'da `system-test` yok | `.github/workflows/ci.yml` | Tarayıcı testi yazmıyoruz; model/entegrasyon testleri yeterli |
| Geliştirme/test SQLite, canlı PostgreSQL | `Gemfile`, `config/database.yml` | Render ücretsiz planında kalıcı disk yok |
| Canlıda önbellek `memory_store`, Cable `async` | `production.rb`, `cable.yml`, `cache.yml` | Ücretsiz planda tek veritabanı var |
| Canlıda Active Job `async`, zamanlanmış iş yok | `production.rb` | Render ücretsiz planı 15 dk sonra uyuyor; zamanlanmış iş güvenilir değil. Zaman kuralları temsilci talep listesini açtığında da uygulanıyor |
| Testler tek iş parçacığında | `test/test_helper.rb` | 50+ testte Rails thread paralelliği SQLite'ı kilitliyordu |
| `first_response_due_at` `before_create` ile yazılır | `app/models/ticket.rb` | Türetilmiş alan; AGENT.md callback kuralına uygun |
| Persona ve maskeli metin `before_create` ile yazılır | `ticket.rb`, `comment.rb` | Türetilmiş alanlar; iş kuralı değil |
| Ajan API'si `ActionController::API`'den türer | `app/controllers/api/v1/` | Oturum/CSRF yok, Bearer token ile kimlik |
| Deploy Render'da Docker ile | `Dockerfile` | Render'ın Ruby ortamında Ruby 4.0.7 desteği belirsizdi |
| E-posta SMTP değil Resend HTTPS API ile | `config/initializers/resend_delivery.rb` | Render ücretsiz planı 25/465/587 portlarını kapatıyor (Eylül 2025) |
| Arayüz dili Türkçe (`default_locale = :tr`) | `config/locales/tr.yml` | Hata ve alan adları Türkçe; rails-i18n gem'i yerine kendi çevirimiz |
| Render Health Check Path = `/up` | Render ayarı | Ana sayfa yokken `/` 404 dönüyor ve deploy başarısız sayılıyordu |

## 8. Çalıştırma (Windows)

```powershell
ruby bin/rails server      # http://localhost:3000
ruby bin/rails test        # testler
ruby bin/rubocop           # stil
```
