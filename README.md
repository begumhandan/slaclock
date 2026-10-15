# SLA Clock — Destek talebi yönetimi

[![CI](https://github.com/begumhandan/slaclock/actions/workflows/ci.yml/badge.svg)](https://github.com/begumhandan/slaclock/actions/workflows/ci.yml)

**Canlı:** https://slaclock.onrender.com  ·  **İlham kaynağı:** Zendesk Support (uygulamada orijinal marka, ad veya logo kullanılmaz)

> YZM379 · Ruby on Rails 8 · "Bir haftada aort dilimi" ödevi

---

## Aort dilimi

**Talep gelir → atanır → yanıtlanır → çözülür**, ilk yanıt SLA'sıyla birlikte.

Zendesk'in müşteriye para ödeten çekirdeği budur: müşteri talebinin kaybolmaması, doğru kişiye gitmesi ve söz verilen sürede yanıtlanması. Bu sözün adı SLA'dır. Dilim şunları uçtan uca kapsıyor:

- Durum akışı: `new → open → pending / on_hold → solved → closed` (yasak geçişler testli)
- Zaman kuralları: önceliğe göre ilk yanıt SLA'sı, pending'de 7 gün yanıt gelmezse otomatik çözme, solved'dan 4 gün sonra kapanma (hepsi `travel_to` ile test ediliyor)
- Kullanılabilir pas (aşağıda): iş takvimine göre çalışan, duraklatılabilen ve kendini açıklayan SLA

---

## Faz 1 — Fortune 500 genel tablo

| Soru | Cevap | Kaynak |
|---|---|---|
| a. Değerleme aralığı | **En küçük:** QVC Group (sıra 433), piyasa değeri **18,9 milyon $**. **En büyük:** Nvidia (sıra 16), piyasa değeri **4,24 trilyon $**. Listenin toplam piyasa değeri 55 trilyon $. Not: Fortune 500 piyasa değerine göre değil gelire göre sıralanır (2026 giriş eşiği: 7,5 milyar $ gelir). Bu yüzden gelirce büyük ama piyasa değeri çok düşük şirketler de listede. 28 şirketin (ör. State Farm, Publix) halka açık olmadığı için piyasa değeri yok. | [Fortune 500 2026 listesi, "Market Value" sütunu](https://fortune.com/ranking/fortune500/) · [Fortune basın bülteni, 3 Haz 2026](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500) |
| b. Çalışan sayısı aralığı | **En az:** BitGo Holdings, 603 kişi. **En çok:** Walmart, 2.100.000 kişi (ikisi de 2026 listesi). Listenin toplamı 30,5 milyon kişi, yani şirket başına ortalama yaklaşık 61.000 (hesap: 30,5M / 500). | [Fortune 500 2026 listesi, "Employees" sütunu](https://fortune.com/ranking/fortune500/) · [Fortune, 19 Haz 2026](https://fortune.com/2026/06/19/fortune-500-employment-profits-revenue-hiring-jobs-ai/) |
| c. Kullanılan SaaS sayısı | 10.000+ çalışanlı büyük işletmelerde **ortalama 660 uygulama** | [Zylo 2025 SaaS Management Index](https://zylo.com/news/2025-saas-management-index) |
| d. Yıllık SaaS harcaması | Aynı segmentte **ortalama 284 milyon $/yıl**; çalışan başına 4.830 $ | [Zylo 2025 SaaS Management Index](https://zylo.com/news/2025-saas-management-index) |

**Yöntem notu:** Zylo verisi doğrudan Fortune 500 için değil, 10.000+ çalışanlı şirketler segmenti için. Fortune 500'de şirket başına ortalama çalışan sayısı yaklaşık 61.000 olduğundan bu segment en yakın vekil ölçü. Derste sınıfça yaptığımız kaba tahmin (en az 100 SaaS, en az 100 milyon $/yıl) bu verilerle uyumlu; gerçek rakamlar tahminin birkaç katı.

---

## SaaS seçimi ve Fortune 500 kanıtı

**Seçilen ürün:** Zendesk Support (müşteri destek talebi yönetimi)

**Fortune 500 kanıtı:** Uber, Zendesk müşterisi. Zendesk Support'u 2010'dan beri sürücü ve yolcu desteği için kullanıyor; yaklaşık 1.000 destek temsilcisi var ([Zendesk müşteri hikâyesi: Uber](https://www.zendesk.com/customer/uber/)). Uber, 2026 Fortune 500 listesinde: gelir 52,0 milyar $, 34.000 çalışan ([Fortune 500 profili](https://fortune.com/company/uber-technologies/fortune500)).


---

## Faz 2 — Ölçek ve maliyet tahmini

### Zendesk kaç satır?

Zendesk'in ana uygulaması bir Rails monolitidir. Zendesk'te kıdemli mühendis olan Cristian Planas ve Anatoly Mikhaylov'un EuRuKo 2024 konuşmasının başlığı **"2,000 Engineers, 2 Million Lines of Code"**. Konuşmanın içinde monolit ve özel gem'leri için **"1,6 milyon satırın üzerinde"** deniyor ([RubyEvents](https://www.rubyevents.org/talks/2-000-engineers-2-million-lines-of-code-the-history-of-a-rails-monolith-euruko-2024)).

**Tahminim: yalnızca monolit için yaklaşık 1,6–2 milyon satır.** Mikroservisler, mobil uygulamalar ve frontend bu sayıya dahil değil. Hocanın verdiği yaklaşık 300.000 satır ölçeğinin 5–6 katı.

**Yöntem:** Şirketin kendi mühendislerinin herkese açık konuşması (birincil kaynak). Çapraz kontrol için: Zendesk'in 2020 yıllık raporuna göre AR-GE biriminde yaklaşık 1.090 çalışan vardı ([10-K, 2020](https://www.sec.gov/Archives/edgar/data/1463172/000146317221000054/zen-20201231.htm)).

### Bugünün coding agent'larıyla ne tutar?

Varsayımlar:
- Satır başına yaklaşık 10 token (ders slaytındaki varsayım).
- Claude Opus 5.5 API fiyatı: girdi 4 $/MTok, çıktı 20 $/MTok ([Claude fiyatlandırma](https://platform.claude.com/docs/en/about-claude/pricing)).
- Ajan döngülerinde okunan (girdi) token, yazılan (çıktı) token'ın kabaca 10–30 katı. Bu benim kaba varsayımım, kendi kullanımımla güncellenecek.

| Kapsam | Satır | Çıktı token | Kaba token maliyeti | Süre |
|---|---|---|---|---|
| Zendesk monolitinin tamamı | ~1,6M | ~16M | çıktı ~320 $ + girdi ~640–1.900 $ ≈ **1.000–2.500 $** (düzeltme turları hariç) | haftalar (tek oturuma sığmaz) |
| Benim aort dilimim (tahmin) | ~3.000–6.000 (testler dahil) | ~30–60k | formüle göre ~2–8 $; düzeltme turlarıyla **~10–40 $** API ya da mevcut abonelik | **2–3 gün** |
| Benim aort dilimim (**gerçek**) | ~1.760 (745 Ruby + 306 görünüm + 152 CSS + 561 test) | ~205k çıktı; 85,6M önbellekten okuma + 0,9M önbelleğe yazma | **~46 $** liste fiyatıyla (abonelikle ödendi) | **1 gün** (15 Ekim, molalar dahil ~9,5 saat) |

**Karşılaştırma için lisans maliyeti:** Zendesk Suite Professional'ın liste fiyatı temsilci başına aylık 115 $ (yıllık ödemede) ([Zendesk fiyatlandırma](https://www.zendesk.com/pricing/)). Uber ölçeğinde 1.000 temsilci için liste fiyatıyla yılda yaklaşık 1,38 milyon $ eder. Enterprise fiyatı açıklanmıyor ve kurumsal indirimleri bilmiyorum; bu rakam sadece büyüklük mertebesini göstermek için.

**Tahmin ile gerçeğin farkı:** Tahminim 10–40 $ idi, gerçek ~46 $ oldu. Fark çıktıdan değil girdiden geliyor: ajan her turda bütün bağlamı (sohbet, dosyalar, loglar) yeniden okuyor. Okunan token, yazılan token'ın yaklaşık 400 katı. Yani maliyeti kod yazmak değil, ajana bağlamı tekrar tekrar "anlatmak" belirliyor. Rakamlar bu proje için tek bir uzun sohbetten ölçüldü (araştırma ve kurulum sorunları dahil). Satır sayıları `wc -l` ile, token sayıları oturum kayıtlarından sayıldı; önbellek fiyatları için standart oranlar (okuma 0,1×, yazma 2×) varsayıldı.

**Sonuç:** Kopyalamanın token maliyeti, lisans maliyetinin yanında küçük kalıyor. Pahalı olan kısım, doğrulama süresi ve ürünün bir sonraki ihtiyacını tasarlamak.

---

## Kullanılabilir pas: çözdüğüm kullanıcı acısı

**Tek cümle:** Çok adımlı süreçlerde ve farklı saat dilimlerinde SLA takibinin "zor ve bazen yanlış" olduğunu söyleyen destek ekiplerinin acısını çözdüm. Benim klonumda SLA ekibin iş takvimine (mesai saatleri, resmi tatiller, saat dilimi) göre hesaplanıyor, "üçüncü taraf bekleniyor" durumunda duruyor ve her talepte SLA'nın neden o saatte dolduğunu adım adım gösteriyor.

**Kaynaklar (kullanıcı yorumları):**
- _"SLA tracking across multiple time zones and multiple step processes is tricky and sometimes incorrect."_ (Otomotiv sektörü, 30 Eylül 2026, [AWS Marketplace yorumları](https://aws.amazon.com/marketplace/reviews/reviews-list/prodview-3rztyxjwcucg2?page=2), [15 Ekim 2026 arşiv kopyası](https://web.archive.org/web/20261015134218/https://aws.amazon.com/marketplace/reviews/reviews-list/prodview-3rztyxjwcucg2?page=2))
- _"Standard features like SLA (...) should be more accessible and not require two days of support"_ (Anonim, 9 Ekim 2026, aynı sayfa ve [arşiv kopyası](https://web.archive.org/web/20261015134218/https://aws.amazon.com/marketplace/reviews/reviews-list/prodview-3rztyxjwcucg2?page=2))
- Zendesk topluluğundaki "Functionality to pause an SLA" fikri: 2017'den beri açık, 47 oy, 66 yanıt. Kullanıcılar on-hold'da (üçüncü taraf ya da geliştirme ekibi beklenirken) SLA'nın durmasını istiyor ([Zendesk Community](https://community.zendesk.com/ideas/functionality-to-pause-an-sla-5356))
- Zendesk'in kendi dokümanına göre duraklatma yalnızca belirli metriklerde ve standart durumlarda mümkün ([Zendesk yardım makalesi](https://support.zendesk.com/hc/en-us/articles/4408825745690-Can-I-pause-the-SLA-timer-or-reset-it-under-certain-conditions))

---

## Nasıl denenir?

1. https://slaclock.onrender.com adresini açın. Ücretsiz sunucu uyuyorsa ilk açılış 30–60 saniye sürebilir.
2. **Talep aç** ile giriş yapmadan bir talep oluşturun (öncelik seçin).
3. **Temsilci girişi** yapın (hesap bilgisi sunumda verilir) → **Talepler** → talebe tıklayın.
4. **İlk yanıt SLA'sı** kutusunda son tarihi, **"SLA neden bu saatte?"** ile hesabın adımlarını görün.
5. **→ Beklemede (3. taraf)** yapın: SLA ⏸ durur. **→ Açık** yapınca kaldığı yerden devam eder.
6. Yanıt yazın (iç not ilk yanıt sayılmaz), sonra **Çözüldü → Kapandı**.

## Testler

```bash
bin/rails test     # 80+ test: durum akışı, yasak geçişler, SLA (travel_to), zaman kuralları, ekranlar, güvenlik
bin/rubocop
```

Testler her push'ta GitHub Actions'ta çalışır (yukarıdaki rozet). Zaman kurallarının testleri `test/models/ticket_sla_test.rb` ve `test/models/ticket_time_rules_test.rb` içinde.

## Kurulum

```bash
bin/setup          # gem'ler, veritabanı, seed (yerel temsilci: temsilci@slaclock.test / slaclock123)
bin/rails server   # http://localhost:3000
```

Windows'ta komutların başına `ruby` ekleyin (`ruby bin/rails server`). Windows'a özgü ayarlar AGENT.md'de "Konvansiyondan sapmalar" bölümünde.

## Yapamadıklarım

- **E-posta kanalı yok.** Talepler yalnızca web formundan geliyor ve müşteriye e-posta bildirimi gitmiyor. Bunun yerine talebi açan müşteri, kendisine özel, tahmin edilemeyen bir linke (`/t/:token`) yönlendiriliyor: talebin durumunu ve ekibin yanıtlarını orada görüyor (iç notları görmüyor), oradan yanıt yazıyor. Yanıtı "müşteri bekleniyor" ya da "çözüldü" durumundaki talebi otomatik olarak yeniden açıyor. Eksik olan: müşteri yeni yanıt geldiğini kendiliğinden öğrenmiyor, sayfaya kendisi bakması gerekiyor; linki kaybederse talebe ulaşamıyor.
- **Ekip başına farklı saat dilimi yok.** SLA, tek bir iş takvimine (İstanbul, Pzt–Cuma 09:00–18:00) göre hesaplanıyor. Yorumdaki "birden çok saat dilimi" acısının yalnızca ilk adımını çözdüm: hesap saat dilimine ve tatile göre doğru ve açıklanabilir, ama ekip veya marka başına ayrı takvim seçilemiyor.
- **Dini bayramlar ve arife yarım günleri takvimde yok.** Yalnızca sabit tarihli resmi tatiller seed ile ekleniyor; tatil arayüzden eklenemiyor.
- **Yalnızca ilk yanıt SLA'sı var.** "Sonraki yanıt süresi" ve "çözüm süresi" SLA'ları yok.
- **Öncelik sonradan değiştirilemiyor.** Talep açılırken seçiliyor; değişseydi SLA'nın yeniden hesaplanması gerekirdi.
- **Zamanlanmış iş çalışmıyor.** Render ücretsiz planı uygulamayı 15 dakika sonra uyutuyor. Otomatik çözme ve kapanma kuralları `TimeRulesJob` olarak yazıldı, ama canlıda temsilci talep listesini açtığında uygulanıyor.
- **Şifre sıfırlama canlıda çalışmıyor, bu yüzden "Şifremi unuttum" linki gizlendi.** Render'ın ücretsiz planı SMTP portlarını kapattığı için e-postayı Resend'in HTTPS API'si ile gönderecek kodu yazdım (`config/initializers/resend_delivery.rb`, testli). E-posta hazırlanıp Resend'e ulaşıyor, ama Resend canlıdaki API anahtarını `401 API key is invalid` diyerek reddetti; birkaç denemede çözemedim. Anahtar düzeltilince link `app/views/sessions/new.html.erb` içinde tek satırla geri açılabilir.
- **Temsilci yönetimi yok.** Temsilci hesabı seed ile oluşturuluyor; arayüzden kayıt veya ekip yönetimi yok.
- **Tarayıcı (system) testleri yok.** CI'da model ve controller testleri çalışıyor.
- **Ücretsiz altyapı sınırları:** İlk istekte uyanma gecikmesi var ve Render'ın ücretsiz veritabanının süresi sınırlı.

## AGENT.md

Ajanla ortak sözlük, yasak sihirler, test kuralları, **kural haritası** (hangi kural hangi dosyada) ve konvansiyondan sapmalar: [AGENT.md](AGENT.md)
