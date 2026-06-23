# Vendor Payment Monitor

A portfolio project simulating a real-world SAP ABAP application: a
color-coded ALV report that automates the monitoring of overdue vendor
payments, built with Object-Oriented ABAP.

> Mock data is used in place of live database access (`LFB1`, `BSIK`,`BSAK`) 
> The architecture is deliberately structured so that swapping
> mock data for real Open SQL access only requires changing one class —
> see [docs/architecture.md](docs/architecture.md).

## Business scenario

An AP team currently tracks overdue vendor invoices by exporting a report
to Excel and manually color-coding/calculating "days overdue" by hand —
slow, error-prone, and inconsistent between clerks. This program replaces
that workflow with a single ABAP report that classifies and color-codes
every open invoice automatically.

Full write-up: [docs/business-scenario.md](docs/business-scenario.md)

## What it does

- Loads open vendor invoices (mocked `LFB1` + `BSIK`/`BSAK` data).
- Classifies each invoice by payment status:
  - 🔴 **CRITICAL** — overdue more than 30 days
  - 🟡 **WARNING** — overdue 1–30 days
  - 🟢 **ON TIME** — not yet due
- Displays the result in a color-coded ALV grid with columns: Vendor ID,
  Vendor Name, Invoice Number, Amount, Currency, Due Date, Days Overdue,
  Status.
- Lets the user filter by status from the selection screen (All /
  Critical / Warning / On Time).
- Adds a custom toolbar button, **"Export to Excel"**, to download the
  current list.

## Technical architecture 
Object-Oriented ABAP with an MVC-like split: a domain-types class, a data
provider (the "model"), an ALV display class (the "view"), and a
controller class that ties them together, fronted by a thin executable
report.

Full write-up: [docs/architecture.md](docs/architecture.md)


## How to run in an SAP system

Requires SAP NetWeaver **7.40 SP08** or higher (uses inline declarations
and constructor expressions).

1. **Create the classes**, in this order (each depends on the previous
   one), via SE24 or ADT — paste the matching file from `src/` into the
   class's source-code editor:
   1. `ZCL_PAYMENT_ENTITY`
   2. `ZCL_PAYMENT_DATA_PROVIDER`
   3. `ZCL_PAYMENT_ALV_DISPLAY`
   4. `ZCL_PAYMENT_MONITOR`

2. **Create the executable program** `ZPAYMENT_MONITOR` (SE38/ADT) and
   paste in `src/ZPAYMENT_MONITOR.abap`.

3. **Create Screen 100** (`Goto → Screens` in SE38, or via SE51):
   - Add one **Custom Control** named `ALV_CONTAINER` on the screen,
     sized to fill the screen area.
   - Flow logic should call:
     ```
     PROCESS BEFORE OUTPUT.
       MODULE status_0100.
       MODULE display_alv_0100.

     PROCESS AFTER INPUT.
       MODULE user_command_0100.
     ```
     (these three modules are already implemented in
     `ZPAYMENT_MONITOR.abap`).

   > Dynpros are screen-painter artifacts and cannot be represented as
   > flat ABAP source text — this is the one setup step that must be
   > done interactively in the SAP GUI, in any SAP system.

4. **Create GUI status `STATUS100`** (`Goto → Status` in SE38) with
   function codes `BACK`, `EXIT`, `CANCEL` mapped to the standard
   back/exit/cancel buttons.

5. **Create title `TITLE100`**, e.g. "Vendor Payment Monitor".

6. **Activate** all objects, then run `ZPAYMENT_MONITOR` via SE38/SA38 (or
   F8 in ADT). Choose a status filter on the selection screen and execute.

## Roadmap 

See "Possible extensions" in [docs/architecture.md](docs/architecture.md)
— includes swapping in real `LFB1`/`BSIK`/`BSAK` access, ABAP Unit tests
for the status logic, aging buckets, and abap2xlsx-based exports.

---

# Türkçe

Gerçek bir SAP ABAP uygulamasını simüle eden bir portfolyo projesi:
vadesi geçmiş tedarikçi ödemelerinin takibini otomatikleştiren, renk
kodlu bir ALV raporu. Nesne Yönelimli ABAP (OO ABAP) ile geliştirilmiştir.

> canlı veritabanı erişimi (`LFB1`, `BSIK`, `BSAK`) yerine sahte (mock)
> veri kullanılmıştır. Mimari, mock veriden gerçek Open SQL erişimine
> geçişin sadece tek bir sınıfı değiştirerek yapılabilmesi için bilinçli
> olarak bu şekilde kurgulanmıştır — bkz.
> [docs/architecture.md](docs/architecture.md).

## İş senaryosu 

Bir Borç Yönetimi (AP) ekibi, vadesi geçmiş tedarikçi faturalarını şu an
bir raporu Excel'e aktarıp "vadesi geçen gün sayısını" elle hesaplayıp
renklendirerek takip ediyor — bu yöntem yavaş, hataya açık ve
çalışandan çalışana tutarsız sonuçlar veriyor. Bu program, bu iş akışını
her açık faturayı otomatik olarak sınıflandıran ve renklendiren tek bir
ABAP raporuyla değiştiriyor.

Tam yazı: [docs/business-scenario.md](docs/business-scenario.md)

## Ne yapar

- Açık tedarikçi faturalarını yükler (mock `LFB1` + `BSIK`/`BSAK` verisi).
- Her faturayı ödeme durumuna göre sınıflandırır:
  - 🔴 **CRITICAL (Kritik)** — 30 günden fazla vadesi geçmiş
  - 🟡 **WARNING (Uyarı)** — 1–30 gün vadesi geçmiş
  - 🟢 **ON TIME (Vadesinde)** — henüz vadesi gelmemiş
- Sonucu şu sütunlarla renk kodlu bir ALV grid'inde gösterir: Tedarikçi
  No, Tedarikçi Adı, Fatura Numarası, Tutar, Para Birimi, Vade Tarihi,
  Vadesi Geçen Gün Sayısı, Durum.
- Kullanıcının seçim ekranından duruma göre filtreleme yapmasını sağlar
  (Tümü / Kritik / Uyarı / Vadesinde).
- Mevcut listeyi indirmek için özel bir araç çubuğu butonu olan
  **"Export to Excel"** ekler.

## Teknik mimari 

MVC benzeri bir ayrıma sahip Nesne Yönelimli ABAP: bir domain-types
sınıfı, bir veri sağlayıcı ("model"), bir ALV görüntüleme sınıfı
("view") ve bunları birbirine bağlayan, ince bir çalıştırılabilir
rapor tarafından çağrılan bir controller sınıfı.

Tam yazı: [docs/architecture.md](docs/architecture.md)



## SAP sisteminde nasıl çalıştırılır

1. **Sınıfları oluşturun**, bu sırayla (her biri öncekine bağımlıdır),
   SE24 veya ADT üzerinden — `src/` klasöründeki ilgili dosyayı sınıfın
   kaynak kodu düzenleyicisine yapıştırın:
   1. `ZCL_PAYMENT_ENTITY`
   2. `ZCL_PAYMENT_DATA_PROVIDER`
   3. `ZCL_PAYMENT_ALV_DISPLAY`
   4. `ZCL_PAYMENT_MONITOR`

2. **Çalıştırılabilir programı oluşturun** `ZPAYMENT_MONITOR` (SE38/ADT)
   ve `src/ZPAYMENT_MONITOR.abap` içeriğini yapıştırın.

3. **100 numaralı ekranı oluşturun** (SE38'de `Goto → Screens` veya
   SE51 üzerinden):
   - Ekranı kaplayacak boyutta, `ALV_CONTAINER` adında bir **Custom
     Control** ekleyin.
   - Akış mantığı (flow logic) şunu çağırmalı:
     ```
     PROCESS BEFORE OUTPUT.
       MODULE status_0100.
       MODULE display_alv_0100.

     PROCESS AFTER INPUT.
       MODULE user_command_0100.
     ```
     (bu üç modül `ZPAYMENT_MONITOR.abap` içinde zaten implemente
     edilmiştir).

   > Dynpro'lar screen-painter çıktısıdır ve düz ABAP kaynak metni
   > olarak temsil edilemez — bu, herhangi bir SAP sisteminde SAP
   > GUI üzerinden interaktif olarak yapılması gereken tek kurulum
   > adımıdır.

4. **`STATUS100` GUI durumunu oluşturun** (SE38'de `Goto → Status`),
   `BACK`, `EXIT`, `CANCEL` fonksiyon kodlarını standart geri/çıkış/iptal
   butonlarına eşleyin.

5. **`TITLE100` başlığını oluşturun**, örn. "Vendor Payment Monitor".

6. Tüm nesneleri **aktive edin**, ardından `ZPAYMENT_MONITOR`'u SE38/SA38
   üzerinden (veya ADT'de F8) çalıştırın. Seçim ekranında bir durum
   filtresi seçip çalıştırın.

## Yol haritası

[docs/architecture.md](docs/architecture.md) içindeki "Possible
extensions" bölümüne bakın — gerçek `LFB1`/`BSIK`/`BSAK` erişimine
geçiş, durum mantığı için ABAP Unit testleri, aging bucket'ları ve
abap2xlsx tabanlı export gibi başlıkları içerir.
