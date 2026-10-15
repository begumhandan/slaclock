# [SlacLock] — Destek talebi yönetimi

![CI](https://github.com/begumhandan/[REPO]/actions/workflows/ci.yml/badge.svg)

**Canlı:** [[URL](https://slaclock.onrender.com/)]  ·  **İlham kaynağı:** Zendesk Support (uygulamada orijinal marka, ad veya logo kullanılmaz)

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

_[İsteğe bağlı: ikinci bir Fortune 500 müşterisi eklemek kanıtı güçlendirir.]_

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
| Benim aort dilimim (**gerçek**) | _[cloc çıktısı]_ | _[ajan arayüzünden]_ | _[$]_ | _[gün / saat]_ |

**Karşılaştırma için lisans maliyeti:** Zendesk Suite Professional'ın liste fiyatı temsilci başına aylık 115 $ (yıllık ödemede) ([Zendesk fiyatlandırma](https://www.zendesk.com/pricing/)). Uber ölçeğinde 1.000 temsilci için liste fiyatıyla yılda yaklaşık 1,38 milyon $ eder. Enterprise fiyatı açıklanmıyor ve kurumsal indirimleri bilmiyorum; bu rakam sadece büyüklük mertebesini göstermek için.

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

## Kurulum

```bash
bin/setup
bin/rails test
bin/dev
```

## Yapamadıklarım

_[Dürüstçe doldurulacak. Örnek: e-posta kanalı yok, sadece web formu; çoklu marka yok; ...]_

## AGENT.md

Ajanla ortak sözlük, yasak sihirler ve kural haritası (hangi kural hangi dosyada) için: [AGENT.md](AGENT.md)
