# Technical Architecture — Vendor Payment Monitor

## Why it's built this way

The whole thing is split into small classes on purpose, each with one job:

- **Separation of concerns** — data access, business rules, and the
  on-screen presentation each live in their own class. That means you can
  change how an invoice gets fetched without touching how it's displayed,
  and vice versa.
- **Testability** — the rule that decides whether something is CRITICAL,
  WARNING, or ON TIME lives in exactly one place
  (`ZCL_PAYMENT_DATA_PROVIDER->DETERMINE_STATUS`), and it doesn't know
  anything about the UI. That means you can unit-test it in isolation with
  ABAP Unit, no screen required.
- **Swappable persistence** — the mock data provider exposes the same
  contract a real Open-SQL-based one would. So when it's time to plug into
  the live `LFB1`/`BSIK`/`BSAK` tables, you only touch that one class —
  nothing else needs to know or care.

## Who does what

| Class                          | Layer        | Responsibility |
|---------------------------------|--------------|-----------------|
| `ZCL_PAYMENT_ENTITY`            | Domain types | Shared structures/constants (`ty_payment_item`, `ty_vendor_master`, `ty_open_item`, status constants). Never instantiated. |
| `ZCL_PAYMENT_DATA_PROVIDER`     | Data access  | Produces `ty_payment_items` from (mock) vendor master + open items; owns the status/days-overdue calculation. |
| `ZCL_PAYMENT_ALV_DISPLAY`       | Presentation | Renders `ty_payment_items` as a color-coded ALV grid; owns toolbar/export behavior. |
| `ZCL_PAYMENT_MONITOR`           | Controller   | Orchestrates provider → filter → display; owns the status-filter constants used by the selection screen. |
| `ZPAYMENT_MONITOR`               | Entry point  | Selection screen, screen flow (PBO/PAI), instantiates the controller. |

## How a request flows through it

```
ZPAYMENT_MONITOR (selection screen: status filter)
        │
        ▼
ZCL_PAYMENT_MONITOR->run( iv_status_filter )
        │
        ├─► ZCL_PAYMENT_DATA_PROVIDER->get_payment_overview( )
        │         │
        │         ├─ get_mock_vendor_master()   ~ SELECT * FROM lfb1
        │         ├─ get_mock_open_items()      ~ SELECT * FROM bsik
        │         └─ determine_status()          → CRITICAL/WARNING/ON_TIME
        │
        ├─► apply_status_filter( )               (FILTER #( ... WHERE status = ... ))
        │
        └─► ZCL_PAYMENT_ALV_DISPLAY->display( )
                  ├─ build_alv_data()    → maps status to ROW_COLOR
                  ├─ build_fieldcatalog()
                  ├─ build_layout()      → LVC_S_LAYO-INFO_FNAME = 'ROW_COLOR'
                  └─ CL_GUI_ALV_GRID->set_table_for_first_display()
```

## How the status/color rule works

It's all decided in one place, `ZCL_PAYMENT_DATA_PROVIDER->DETERMINE_STATUS`:

| Days overdue (`SY-DATUM - net_due_date`) | Status     | ALV row color            |
|---|---|---|
| `> 30`                                    | CRITICAL   | Red, intensified (`C61`) |
| `1 – 30`                                  | WARNING    | Yellow, intensified (`C31`) |
| `<= 0` (not yet due)                      | ON TIME    | Green, intensified (`C51`) |

The 30-day threshold is just one constant
(`ZCL_PAYMENT_ENTITY=>GC_CRITICAL_THRESHOLD`), so if the business ever wants
to move that line, it's a one-line change.

One thing worth calling out: the **data provider** only ever hands back a
business-level `STATUS` (`CRITICAL`/`WARNING`/`ON_TIME`) — it has no idea
that red or yellow exist. It's the **display class** that decides what each
status looks like (`C61`/`C31`/`C51`). That split is deliberate: if someone
builds a Fiori front end later, it can reuse the data provider as-is and
pick whatever colors it wants.

## A few notes on the ALV implementation

- It uses **`CL_GUI_ALV_GRID`** rather than `CL_SALV_TABLE` because we need
  direct control over two things `CL_SALV_TABLE` makes awkward: per-row
  coloring (`LAYOUT-INFO_FNAME`) and a custom toolbar button via the
  `TOOLBAR`/`USER_COMMAND` events. Both are hard requirements here.
- Row coloring works by sneaking in a technical `ROW_COLOR` field (type
  `CHAR3`, e.g. `'C61'` = color 6, intensified) on the **display-only**
  structure `ZCL_PAYMENT_ALV_DISPLAY=>TY_ALV_LINE`. That field is
  deliberately left out of the field catalog so it never shows up as a
  column — the grid only picks it up because `LAYOUT-INFO_FNAME` points to
  it by name.
- The "Export to Excel" button is added in the `TOOLBAR` event handler and
  handled in `USER_COMMAND`. The export itself just uses
  `CL_GUI_FRONTEND_SERVICES=>FILE_SAVE_DIALOG` + `GUI_DOWNLOAD` with a
  tab-separated payload, which Excel opens natively without any fuss. If you
  ever need a fully styled `.xlsx` with multiple sheets, swap this for the
  open-source **abap2xlsx** library — no other class needs to change.
- Standard ALV functions (sort, generic column filter, totals via
  `DO_SUM`) still work out of the box, alongside the selection-screen
  status filter.

## What's simplified, on purpose

- **Dynpro (Screen 100)** — `CL_GUI_ALV_GRID` needs a custom control, and
  that can only be created in the Screen Painter (SE51); there's no way to
  express it as flat ABAP source (true of any real SAP system, not a gap in
  this portfolio). Everything else — the report, the PBO/PAI modules — is
  real ABAP source; only the screen layout itself has to be painted by
  hand. See `README.md` → "How to run."
- **Single company code** — the mock data only simulates company code
  `1000`.
- **No currency conversion** — amounts are shown in whatever currency the
  transaction was originally in; nothing gets converted to a group
  currency.
- **Due-date math is simplified** — in a real system, the BSIK due date
  comes from a baseline date (`ZFBDT`) plus payment terms
  (`ZBD1T`/`ZBD2T`/`ZBD3T`). The mock data just stores an already-computed
  `NET_DUE_DATE` instead, so the focus stays on the monitor's own logic
  rather than reimplementing payment-terms math.

# Türkçe

## Neden bu şekilde kurgulandı

Her şey bilinçli olarak küçük sınıflara bölündü, her birinin tek bir işi
var:

- **Sorumlulukların ayrılması** — veri erişimi, iş kuralları ve ekrana
  basma işi her biri kendi sınıfında yaşıyor. Bu sayede bir faturanın nasıl
  çekildiğini değiştirirken nasıl gösterildiğine dokunmana gerek kalmıyor,
  tersi de geçerli.
- **Test edilebilirlik** — bir kaydın CRITICAL, WARNING ya da ON TIME
  olduğuna karar veren kural tek bir yerde yaşıyor
  (`ZCL_PAYMENT_DATA_PROVIDER->DETERMINE_STATUS`) ve UI hakkında hiçbir
  şey bilmiyor. Bu da onu ekran gerektirmeden ABAP Unit ile tek başına
  test edebilmen anlamına geliyor.
- **Değiştirilebilir veri kaynağı** — mock veri sağlayıcı, gerçek
  Open-SQL tabanlı bir sağlayıcının sunacağı aynı arayüzü sunuyor. Yani
  gerçek `LFB1`/`BSIK`/`BSAK` tablolarına bağlanma vakti geldiğinde sadece
  o tek sınıfa dokunman gerekiyor — başka hiçbir şeyin bundan haberi olmasına
  gerek yok.

## Hangi sınıf ne işe yarıyor

| Sınıf                          | Katman        | Sorumluluk |
|---------------------------------|--------------|-----------------|
| `ZCL_PAYMENT_ENTITY`            | Domain types | Ortak yapılar/sabitler (`ty_payment_item`, `ty_vendor_master`, `ty_open_item`, durum sabitleri). Hiçbir zaman instantiate edilmez. |
| `ZCL_PAYMENT_DATA_PROVIDER`     | Veri erişimi  | (Mock) tedarikçi master verisi + açık kalemlerden `ty_payment_items` üretir; durum/vadesi geçen gün hesaplamasının sahibi. |
| `ZCL_PAYMENT_ALV_DISPLAY`       | Sunum | `ty_payment_items`'i renk kodlu bir ALV grid'i olarak gösterir; araç çubuğu/export davranışının sahibi. |
| `ZCL_PAYMENT_MONITOR`           | Controller   | Provider → filtre → görüntüleme akışını yönetir; seçim ekranında kullanılan durum-filtresi sabitlerinin sahibi. |
| `ZPAYMENT_MONITOR`               | Giriş noktası  | Seçim ekranı, ekran akışı (PBO/PAI), controller'ı instantiate eder. |

## Bir istek sistemden nasıl geçiyor

ZPAYMENT_MONITOR (selection screen: status filter)
        │
        ▼
ZCL_PAYMENT_MONITOR->run( iv_status_filter )
        │
        ├─► ZCL_PAYMENT_DATA_PROVIDER->get_payment_overview( )
        │         │
        │         ├─ get_mock_vendor_master()   ~ SELECT * FROM lfb1
        │         ├─ get_mock_open_items()      ~ SELECT * FROM bsik
        │         └─ determine_status()          → CRITICAL/WARNING/ON_TIME
        │
        ├─► apply_status_filter( )               (FILTER #( ... WHERE status = ... ))
        │
        └─► ZCL_PAYMENT_ALV_DISPLAY->display( )
                  ├─ build_alv_data()    → maps status to ROW_COLOR
                  ├─ build_fieldcatalog()
                  ├─ build_layout()      → LVC_S_LAYO-INFO_FNAME = 'ROW_COLOR'
                  └─ CL_GUI_ALV_GRID->set_table_for_first_display()

## Durum/renk kuralı nasıl çalışıyor

Her şey tek bir yerde, `ZCL_PAYMENT_DATA_PROVIDER->DETERMINE_STATUS`
içinde karara bağlanıyor:

| Vadesi geçen gün (`SY-DATUM - net_due_date`) | Durum     | ALV satır rengi            |
|---|---|---|
| `> 30`                                    | CRITICAL   | Kırmızı, yoğun (`C61`) |
| `1 – 30`                                  | WARNING    | Sarı, yoğun (`C31`) |
| `<= 0` (henüz vadesi gelmemiş)                      | ON TIME    | Yeşil, yoğun (`C51`) |

30 günlük eşik tek bir sabit (`ZCL_PAYMENT_ENTITY=>GC_CRITICAL_THRESHOLD`),
yani işin sahipleri bu çizgiyi bir gün değiştirmek isterse, tek satırlık
bir değişiklik yeterli.

Belirtilmesi gereken bir nokta var: **veri sağlayıcı** her zaman sadece
iş seviyesinde bir `STATUS` döndürür (`CRITICAL`/`WARNING`/`ON_TIME`) —
kırmızı veya sarının var olduğundan bile haberi yok. Hangi durumun nasıl
görüneceğine (`C61`/`C31`/`C51`) **görüntüleme sınıfı** karar veriyor. Bu
ayrım bilinçli: ileride biri bir Fiori arayüzü yaparsa, veri sağlayıcıyı
hiç değiştirmeden kullanabilir ve istediği renkleri seçebilir.

## ALV implementasyonu hakkında birkaç not

- `CL_SALV_TABLE` yerine **`CL_GUI_ALV_GRID`** kullanılıyor çünkü
  `CL_SALV_TABLE`'ın zorlaştırdığı iki şeye doğrudan kontrol gerekiyor:
  satır bazlı renklendirme (`LAYOUT-INFO_FNAME`) ve `TOOLBAR`/
  `USER_COMMAND` event'leri üzerinden özel bir araç çubuğu butonu. İkisi
  de burada zorunlu gereksinim.
- Satır renklendirmesi, **sadece görüntüleme için** olan
  `ZCL_PAYMENT_ALV_DISPLAY=>TY_ALV_LINE` yapısına teknik bir `ROW_COLOR`
  alanı (tip `CHAR3`, örn. `'C61'` = renk 6, yoğun) eklenerek çalışıyor.
  Bu alan bilinçli olarak field catalog'dan çıkarılmış, yani hiçbir zaman
  bir sütun olarak görünmüyor — grid bu alanı sadece
  `LAYOUT-INFO_FNAME` adıyla işaret ettiği için okuyor.
- "Export to Excel" butonu `TOOLBAR` event handler'ında eklenip
  `USER_COMMAND`'da işleniyor. Export'un kendisi
  `CL_GUI_FRONTEND_SERVICES=>FILE_SAVE_DIALOG` + `GUI_DOWNLOAD`'ı tab
  ile ayrılmış bir veriyle kullanıyor, Excel bunu sorunsuzca açıyor. Çok
  sayfalı, biçimlendirilmiş bir `.xlsx` gerekirse, bunun yerine açık
  kaynak **abap2xlsx** kütüphanesine geçilebilir — başka hiçbir sınıfa
  dokunmadan.
- Standart ALV fonksiyonları (sıralama, genel sütun filtresi, `DO_SUM`
  ile toplamlar) seçim ekranındaki durum filtresinin yanında kutudan
  çıktığı gibi çalışmaya devam ediyor.

## Bilinçli olarak basitleştirilenler

- **Dynpro (100 numaralı ekran)** — `CL_GUI_ALV_GRID` özel bir control
  gerektiriyor ve bu sadece Screen Painter'da (SE51) oluşturulabiliyor;
  düz ABAP kaynak metni olarak ifade edilmesinin bir yolu yok (bu her
  gerçek SAP sisteminde böyle, bu portfolyoya özgü bir eksiklik değil).
  Geri kalan her şey — rapor, PBO/PAI modülleri — gerçek ABAP kaynak
  kodu; sadece ekran düzeninin kendisi elle çizilmek zorunda. Bkz.
  `README.md` → "How to run."
- **Tek şirket kodu** — mock veri sadece `1000` şirket kodunu simüle
  ediyor.
- **Para birimi çevrimi yok** — tutarlar, işlemin orijinal para
  biriminde gösteriliyor; bir grup para birimine çevrim yapılmıyor.
- **Vade tarihi hesaplaması basitleştirildi** — gerçek bir sistemde BSIK
  vade tarihi, baz tarih (`ZFBDT`) ile ödeme koşullarının
  (`ZBD1T`/`ZBD2T`/`ZBD3T`) toplamından gelir. Mock veri bunun yerine
  doğrudan hesaplanmış bir `NET_DUE_DATE` tutuyor, böylece odak ödeme
  koşulları matematiğini yeniden yazmak değil, monitor'ün kendi
  mantığında kalıyor.
