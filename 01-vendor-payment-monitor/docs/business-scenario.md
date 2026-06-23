# Business Scenario — Vendor Payment Monitor

## The problem

The Accounts Payable team at a manufacturing company works through several
hundred vendor invoices a month, spread across multiple company codes. Right
now, keeping track of what's overdue is a manual chore: once or twice a week,
an AP clerk pulls up a generic open-item report (transaction **FBL1N**),
dumps it into Excel, and goes through it by hand — sorting by due date,
eyeballing which rows look urgent, and writing a formula to work out how many
days an invoice is overdue. Anything that looks critical gets flagged in an
email to the AP team lead, who then has to decide on the fly which payments
to push through first.

## Why this fails

The biggest issue is timing — the report is only ever as fresh as the last
export, so anything that turns urgent mid-week slips through the cracks
until the next run. On top of that, a lot of this comes down to judgment
calls made by hand: the due-date math, the color-coding, deciding what
counts as "critical" versus just a "warning" — and that line moves depending
on which clerk happens to be doing the work. Because everyone keeps their
own copy of the spreadsheet, there's no single version of the truth, and the
team lead often ends up deciding things based on data that's already stale
or contradicts someone else's copy. The real cost shows up in missed
early-payment discounts, late-payment penalties and interest, and vendors
who get tired of being paid late. And when auditors come asking how overdue
items are monitored, there isn't a consistent, repeatable answer to give
them.

## The solution

**Vendor Payment Monitor** gets rid of the spreadsheet step entirely. It's a
single ABAP report that pulls open vendor items straight from the relevant
FI tables — vendor master (LFB1) plus open and cleared items (BSIK/BSAK) in
a live system — and classifies every invoice as **CRITICAL**, **WARNING**,
or **ON TIME** using one rule that's maintained centrally instead of living
in someone's head (details in [architecture.md](architecture.md)). The
result shows up as a color-coded ALV grid, so the team lead can scan the
whole list visually in seconds instead of reading down a spreadsheet column.
Filtering by status is built right into the selection screen, so getting to
"just show me what's critical today" takes two clicks, and there's a
one-click Excel export for the times the data still needs to reach people
outside SAP, like treasury or external auditors.

## Stakeholders

| Role                  | Need                                                          |
|------------------------|----------------------------------------------------------------|
| AP clerk               | Fast, reliable daily view of what needs to be paid first       |
| AP team lead           | Aggregated, trustworthy status overview across all vendors     |
| Internal audit         | Repeatable, rule-based evidence of overdue-item monitoring      |
| Treasury / cash mgmt   | Visibility into upcoming and overdue cash outflows              |


---

# İş Senaryosu — Tedarikçi Ödeme Takip Sistemi

## Sorun

Bir üretim şirketindeki Borç Yönetimi (AP) ekibi, her ay birden fazla şirket
kodunda yüzlerce tedarikçi faturasını işliyor. Şu anda hangi faturaların
vadesinin geçtiğini takip etmek tamamen elle yapılan bir iş: haftada bir
veya iki kez bir AP memuru genel bir açık kalem raporunu (**FBL1N** işlemi)
çekiyor, Excel'e aktarıyor ve elle inceliyor — vade tarihine göre sıralıyor,
hangi satırların acil göründüğünü gözle seçiyor ve bir formülle faturanın
kaç gün geciktiğini hesaplıyor. Kritik görünen her şey e-posta ile AP ekip
liderine bildiriliyor, o da hangi ödemelerin önce yapılacağına anlık olarak
karar veriyor.

## Neden işe yaramıyor

En büyük sorun zamanlama: rapor sadece son Excel aktarımı kadar güncel,
yani hafta ortasında aciliyet kazanan bir şey ancak bir sonraki
çalıştırmada fark ediliyor. Bunun üstüne, işin büyük kısmı elle verilen
kararlara dayanıyor: vade hesaplaması, renklendirme, bir kalemin "kritik"
mi yoksa sadece "uyarı" mı olduğuna karar vermek — ve bu sınır hangi
memurun işi yaptığına göre kayıyor. Herkes kendi Excel kopyasını tuttuğu
için ortada tek bir doğru kaynak yok, bu da ekip liderinin sık sık güncelliğini
kaybetmiş ya da başka birinin kopyasıyla çelişen verilerle karar vermesine
yol açıyor. Gerçek maliyet ise kaçırılan erken ödeme indirimlerinde,
gecikme cezası/faizlerinde ve geç ödemeden yorulan tedarikçilerde ortaya
çıkıyor. Denetçiler vadesi geçen kalemlerin nasıl izlendiğini sorduğunda da
elde tutarlı, tekrarlanabilir bir cevap olmuyor.

## Çözüm

**Vendor Payment Monitor**, Excel adımını tamamen ortadan kaldırıyor. Açık
tedarikçi kalemlerini ilgili FI tablolarından — canlı bir sistemde
tedarikçi ana kaydı (LFB1) ile açık ve kapatılmış kalemler (BSIK/BSAK) —
doğrudan çeken tek bir ABAP raporu bu. Her faturayı, birinin kafasında
değil merkezi olarak tutulan tek bir kurala göre **KRİTİK**, **UYARI** veya
**ZAMANINDA** olarak sınıflandırıyor (detaylar
[architecture.md](architecture.md) dosyasında). Sonuç renk kodlu bir ALV
grid olarak gösteriliyor, böylece ekip lideri tüm listeyi bir Excel
sütununu satır satır okumak yerine saniyeler içinde gözden geçirebiliyor.
Duruma göre filtreleme seçim ekranına gömülü, yani "bugün sadece kritik
olanları göster" iki tıkla yapılabiliyor; verinin SAP dışındaki kişilere
(örneğin hazine veya dış denetçiler) ulaştırılması gerektiğinde de tek
tıkla Excel'e aktarma seçeneği var.

## Paydaşlar

| Rol                    | İhtiyaç                                                          |
|------------------------|-------------------------------------------------------------------|
| AP memuru              | Önce neyin ödenmesi gerektiğine dair hızlı, güvenilir günlük görünüm |
| AP ekip lideri         | Tüm tedarikçiler genelinde toplu, güvenilir durum özeti            |
| İç denetim             | Vadesi geçen kalemlerin izlenmesine dair tekrarlanabilir, kurala dayalı kanıt |
| Hazine / nakit yönetimi | Yaklaşan ve vadesi geçmiş nakit çıkışlarına dair görünürlük        |


