# CHALLENGE_LOG

## Başlangıç noktası

- **Klonlanan ürün:** Zendesk Support (müşteri destek talebi yönetimi) → **SLA Clock**
- **Canlı:** https://slaclock.onrender.com
- **Geçen haftanın son commit'i:** [`39e399a`](https://github.com/begumhandan/slaclock/commit/39e399ad7a3d6e82ca870212f80359b4db46b56a)
  (talep → atama → yanıt → çözüm akışı, iş takvimine göre işleyen ve on-hold'da duran ilk yanıt SLA'sı,
  "Bu saat nereden çıktı?" açıklaması, gizli linkli müşteri sayfası; 120 test, CI yeşil)
- **Bu ürüne kim, neden para ödüyor?** Uber gibi büyük şirketler (Uber, 2010'dan beri ~1.000 temsilciyle) Zendesk'e,
  müşteri talepleri kaybolmasın, doğru kişiye gitsin ve söz verilen sürede (SLA) yanıtlansın diye para ödüyor.
  Liste fiyatıyla temsilci başına aylık 115 $; 1.000 temsilci için yılda ~1,38 milyon $.

## Acı

Bu hafta iki acı birleşiyor:

1. **Destek ekibi müşterinin kişisel verisini gereğinden fazla görüyor, ve bu veri artık yapay zekâya da gidiyor.**
   Bir destek temsilcisinin talebi çözmek için çoğu zaman müşterinin TC kimlik numarasını, telefonunu, kart numarasını
   bilmesi gerekmez; "21–22 yaşında bir mühendislik öğrencisi, Samsun'da" bilgisi bağlamı vermeye yeter.
   Şirketler destek taleplerini LLM'lere ve ajanlara verdikçe bu veri üçüncü taraf modellere de akıyor.
   - Zendesk'te bu sorun biliniyor: hassas veriyi (kart numarası vb.) otomatik tespit edip karartma, ayrı ücretli
     "Advanced Data Privacy and Protection (ADPP)" eklentisiyle geliyor
     ([Zendesk: Automatically detecting sensitive information for redaction (ADPP add-on)](https://support.zendesk.com/hc/en-us/articles/6669399593882-Automatically-detecting-sensitive-information-for-redaction-ADPP-add-on),
     [Redacting ticket content](https://support.zendesk.com/hc/en-us/articles/4408846470170-Redacting-ticket-content)).
     Karartma veriyi siler; temsilciye müşteri hakkında **bağlam** bırakmaz. Benim farkım: veriyi silmek yerine
     bağlamı koruyan sentetik bir profil göstermek ve LLM'e hiç ham veri göndermemek.
   - Türkiye'de KVKK, kişisel verinin "işlendikleri amaçla bağlantılı, sınırlı ve ölçülü" olmasını şart koşuyor
     (6698 sayılı Kanun, madde 4/2-ç). Destek temsilcisinin TC numarasını görmesi bu ilkeyle çelişiyor.
2. **Kullanıcıların SLA ve otomasyon şikâyetleri** (geçen haftadan): "SLA takibi çok adımlı süreçlerde zor ve bazen yanlış"
   ([AWS Marketplace yorumu, 30 Eylül 2026](https://aws.amazon.com/marketplace/reviews/reviews-list/prodview-3rztyxjwcucg2?page=2)),
   "on-hold'da SLA dursun" isteği 2017'den beri açık
   ([Zendesk Community](https://community.zendesk.com/support-7/sla-time-did-not-pause-in-pending-and-on-hold-status-14934)).

## Bu haftanın vaadi

"Geçen hafta talep akışını ve kendini açıklayan SLA'yı getirdim. Bu hafta üzerine şunu ekliyorum:
**destek tarafı — insan temsilci de, yapay zekâ ajanı da — müşterinin gerçek kişisel verisini hiç görmeden çalışsın.**"

Somut olarak:

1. **Gizlilik maskesi (kişisel hedef):** Talep gelince ad, e-posta, telefon, TC no, IBAN, kart numarası maskelenir.
   Temsilci gerçek kimlik yerine tutarlı bir **sentetik profil** görür: "Zeynep Kaya · ~21–22 yaş · mühendislik öğrencisi · Samsun".
   Gerçek veri yalnızca **gerekçe yazılarak** açılır ve her açılış **kayda geçer** (kim, ne zaman, neden).
2. **LLM zekâsı:** Kategori, aciliyet ve "müşterinin 'teşekkürler' mesajı talebi yeniden açsın mı?" kararlarını
   anahtar kelime eşleştirmesi değil, LLM (Groq) verir. LLM'e **yalnızca maskeli metin** gider.
   Asistan yalnızca bilgi tabanına (`config/knowledge_base.yml`) dayanarak yanıt yazar, dayanamazsa yazmaz (halüsinasyona karşı).
3. **Agent-first:** Müşteri tarafındaki bir ajan JSON API ile talep açar, izler, yanıt yazar. Destek asistanı ilk yanıtı
   verir ya da gerekçesiyle **insana devreder** (human-in-the-loop). Ajan için belge: `/llms.txt`.

**Slop testi cümlesi:** "Benimkinde destek ekibi ve yapay zekâ müşterinin gerçek verisini hiç görmüyor; gördükleri,
bağlamı koruyan sentetik bir profil."

## Yapılanlar ve kanıt

> Commit linkleri ve canlı doğrulama, push'tan sonra bu bölüme eklenecek.

**Kod:**

| Ne | Nerede |
|---|---|
| Maskeleme kuralları (e-posta, telefon, TC no, IBAN, kart, ad) | `app/services/privacy_mask.rb` |
| Sentetik profil (takma ad, 2 yıllık yaş aralığı, genelleştirilmiş meslek, il) | `app/services/synthetic_persona.rb` |
| Gerekçeli erişim + erişim kaydı | `TicketsController#reveal`, `app/models/pii_access_log.rb` |
| Temsilci ekranı: maskeli konu/metin, persona, gizlilik kartı | `app/views/tickets/` |
| LLM istemcisi (Groq, anahtar yoksa kapalı) | `app/services/llm_client.rb` |
| Triage: kategori, aciliyet, özet, bilgi tabanına dayalı yanıt ya da devir | `app/services/ticket_triage.rb`, `app/jobs/ai_triage_job.rb` |
| "Teşekkür" niyeti (LLM) | `app/services/reply_intent.rb`, `Ticket#add_customer_reply!` |
| Ajan API'si + belgesi | `app/controllers/api/v1/tickets_controller.rb`, `public/llms.txt` |
| Canlı demo ajanı | `bin/agent-demo` |

**Testler** (gerçek LLM çağrılmaz; `FakeLlm` hem yanıt verir hem kendisine gönderilen her istemi kaydeder):

- LLM'e giden istemlerde gerçek ad, telefon, TC no, e-posta **yok** (`test/jobs/ai_triage_job_test.rb`, `test/models/reply_intent_test.rb`)
- Temsilci sayfasında ve listede gerçek veri yok; gerekçesiz açılmıyor; gerekçeyle açılınca kayda geçiyor (`test/controllers/privacy_screen_test.rb`)
- Kaynak göstermeyen ya da emin olmayan asistan yanıt yayınlamıyor, insana devrediyor (`ai_triage_job_test.rb`)
- LLM aciliyeti yükseltirse SLA yeniden hesaplanıyor, öncelik asla düşürülmüyor (`ai_triage_job_test.rb`, `travel_to`)
- "Teşekkürler, çözüldü" çözülmüş talebi açmıyor; "teşekkürler ama hâlâ gelmedi" açıyor (`reply_intent_test.rb`)
- Ajan API'si: anahtarsız 401, talep açma, iç notları görmeme, müşteri adına yanıt (`test/controllers/api_tickets_test.rb`)

**Canlı demo adımları:**

1. https://slaclock.onrender.com/tickets/new → "Sizi tanımamıza yardımcı olun" alanlarını doldurup, metne telefon/TC no yazarak talep açın.
2. Temsilci olarak talebe bakın: konu ve metinde `[TELEFON]`, `[TC_NO]`; talep sahibi yerine sentetik profil; sağda "Gizlilik maskesi" ve "Yapay zekâ" kartları.
3. "Gerçek veriyi göster" → gerekçe yazın → veri görünür, "Erişim kaydı"na düşer.
4. Ajan: `ruby bin/agent-demo kargo` → asistan bilgi tabanından yanıtlar → ajan "teşekkürler, çözüldü" yazar → talep **Çözüldü**.
5. Ajan: `ruby bin/agent-demo sikayet` → asistan yanıtlamaz, aciliyeti yükseltir, talebi **insana devreder** → kuyrukta "İnsana devredilenler".

**Vaat edip yapamadıklarım / sınırlar:**

- Maskeleme bilerek basit (düz kurallar). Adres, plaka, serbest yazılmış isimler (formda verilmemişse) yakalanmıyor;
  11 haneli her sayı TC no sayılıyor (doğrulama yok). Bitirme projemdeki (Context-Shield AI) daha güçlü yöntemleri,
  patent süreci nedeniyle bu herkese açık repoya koymadım.
- Gerçek adın Türkçe ekli halleri (ör. "Begüm'ün" değil "Begümün") ve "Demir kapı" gibi ad olmayan kullanımlar ayırt edilmiyor.
- "Bilgi tabanı" küçük (6 madde) ve tamamı isteme ekleniyor; gerçek bir vektör araması (RAG) yok.
- Temsilci, gerçek veriyi gördükten sonra yanıtına kopyalarsa bu engellenmiyor (yalnızca kayıt tutuluyor).

## Zaman

> Push'tan sonra kesin rakamlarla güncellenecek.

- **Agent zamanı / maliyeti:** oturum kayıtlarından sayılacak (geçen hafta: ~410k çıktı token, ~165M önbellek okuma, ~85 $).
- **İnsan zamanı:** kararlar, Groq anahtarı, Render ayarları, testleri çalıştırma, push.

**İlk prompt'um (olduğu gibi):** Ödev metnini olduğu gibi yapıştırdım; ardından ajanın sorduğu dört soruya (teslim zamanı, patent nedeniyle maskeleme yönteminin ne kadar paylaşılacağı, LLM sağlayıcısı, kapsam) cevap verdim.

```text
Neredeyiz?
Geçen hafta Fortune 500 şirketlerinin para ödediği bir SaaS ürününü klonladınız.
Emeğiniz gerçek. Yine de bugünkü sunumlarda gördüğümüz tablo şuydu: ekranların
çoğunu yan yana koyup isimleri kapatsak hangisinin kime ait olduğunu söyleyemezdik.
Herkes aşağı yukarı aynı Zendesk’i, aynı renklerle ve aynı “teşekkür edince ticket
yeniden açılmasın” çözümüyle çıkardı.
Bunun adı slop: çok süslü, çok güzel görünen, ama birbirinin aynısı olan çıktı. 4 saat de
uğraşsanız 40 saat de uğraşsanız sonuç değişmiyorsa, sonucu siz değil yapay zekâ
belirliyor demektir. Bu ödev, sizin katkınızın ne olduğunu ortaya koymanız için var.
Bir de odadaki fil var. Sunumların neredeyse tamamı insandan insana kurgulanmıştı:
insan ticket açıyor, insan cevaplıyor, insan sürükleyip bırakıyor. Oysa web trafiğinin
giderek daha büyük bir kısmını agent’lar oluşturuyor. Yarın ticket’ı açan da bir agent
olabilir, cevaplayan da.
Görevler
1. Karar ver: Devam mı, öldür mü?
Projeyi en iyi siz tanıyorsunuz, başınıza gelenleri de siz biliyorsunuz. Üç seçeneğiniz
var:
 Devam et ve üzerine ekle.
 Pivot yap: aynı acıyı başka bir yoldan çöz ya da hocanın önerdiği yöne dön.
 Öldür: gerekçesini yaz ve yeni hedefini belirle.
Kararınızı gerekçesiyle birlikte yazın. “Hocanın ödevini yaptım” demek gerekçe değildir.
Gerekçe “Bundan bir iş çıkar mı?” sorusuna verdiğiniz cevaptır.
2. Repoya CHALLENGE_LOG.md ekle (zorunlu)
Repo kökünde aşağıdaki başlıkları içeren bir dosya olacak:
markdown
# CHALLENGE_LOG

## Başlangıç noktası
- Klonlanan ürün ve canlı URL
- Geçen haftanın son commit'i (link)
- Bu ürüne kim, neden para ödüyor?

## Acı
- Hangi kullanıcının hangi acısı? Kaynak (şikâyet, forum, inceleme linki)

## Bu haftanın vaadi
- "Şuraya kadar getirdim, üzerine şunu ekleyeceğim."

## Yapılanlar ve kanıt
- Commit linkleri, çalışan testler, canlı demo adımları
- Vaat edip yapamadığın ne varsa açıkça yaz

## Zaman
- İnsan zamanı / agent zamanı (dürüstçe)
- İlk prompt'un (olduğu gibi)

## Karar
- Devam / pivot / öldür ve gerekçesi
Vaat edilip kodla kanıtlanmamış bir şey yapılmamış sayılır.
3. Fark katmanı: En az birini yap
1. Agent-first: Kullanıcınız ya da müşteriniz bir agent olsaydı ne değişirdi? Agent’ın
ticket açtığı, agent’ın cevapladığı, gerektiğinde insana devrettiği (human-in-the-
loop) bir akışı canlı gösterin. Unutmayın: sürükle-bırak insan için tasarlanmış bir
harekettir, agent’ın buna ihtiyacı yok.
2. Anahtar kelime değil, LLM zekâsı: “teşekkür”, “acil” gibi kelime eşleştirmeleri
on yıl öncenin çözümüdür. Bu kararları bir LLM’e verin. Gerekiyorsa RAG ile
halüsinasyonu azaltın.
3. Slop testi: Aynı ürünü klonlayan bir arkadaşınızın ekranının yanına sizinkini
koyun. Tek cümleyle söyleyin: “Benimkinde olup onunkinde olmayan şey ___.”
Bu cümleyi kanıtlayın.

4. Kişisel hedefin
Sunumunuz sırasında size özel bir yön verildi. Aşağıdaki tablodan kendi hedefinizi
bulun. Ayrıca kişisel geri bildiriminiz size ayrıca iletilecek. Saçmaladığını düşündüğünüz
bir yer varsa söyleyin.Begüm Gizlilik maskesi: müşterinin gerçek kişisel verisini vermeden, bağlamı
koruyan sentetik bir profili (örneğin “Ayşe, ~21–22 yaş, mühendislik
öğrencisi”) destek tarafına sun. Hedef 100.5. Sunum kuralları
 Geçen hafta gösterdiğinizi tekrar anlatmayın. Doğrudan farkı gösterin.
 Akış: canlı URL → yeni özellik → CHALLENGE_LOG.md → commit geçmişi.
 Render’a nasıl deploy ettiğinizi ve kullandığınız coding agent’ın bunu nasıl
bildiğini (ör. AGENTS.md/CLAUDE.md kuralları) sorabilirim.
Puanlama
Mantık geçen haftakiyle aynı:
 0: Hiçbir şey yapılmamışsa.

 85: CHALLENGE_LOG.md tam, karar gerekçeli, kişisel hedef çalışır halde ve
kanıtlı.
 100: Yukarıdakilere ek olarak fark katmanının (agent-first ve/veya LLM zekâsı)
canlı demoda çalıştığı gösterilmiş.
Kaynaklar
 Alibaba page-agent (GitHub’da “alibaba page-agent”)
 incident.io, Tawk.to, PagerDuty, ServiceNow, Salesforce Einstein
 Ücretsiz/ucuz LLM API’leri: Groq (q ile!), NVIDIA (build.nvidia.com), Hugging
Face
 JEV (typesafe ai system 1)
 Andrew Ng’nin yazılım mühendisliğinin geleceği üzerine son paylaşımları
(“vizyon mühendisi”)
Hayatta kalacağımıza yapacağımız bu .
```

## Karar

**Devam** (üzerine ekle).

Gerekçe — "Bundan bir iş çıkar mı?" sorusuna cevabım: Zendesk klonu tek başına iş değil; herkes aynısını yapabiliyor.
Ama **"destek ekipleri ve yapay zekâ ajanları müşterinin kişisel verisini görmeden çalışsın"** bir iş:
şirketler destek taleplerini LLM'lere verdikçe KVKK/GDPR riski büyüyor ve bunu çözen bir katman satılabilir.
Bu, bitirme projem Context-Shield AI'ın (LLM'e giden veriyi maskeleyen katman) destek sistemine uygulanmış hali;
yani tek seferlik bir ödev değil, üzerinde aylardır çalıştığım alanın gerçek bir kullanım senaryosu.
Klonun kendisi (talep akışı, SLA) bu katmanın altında çalıştığı zemin olarak kalıyor.
