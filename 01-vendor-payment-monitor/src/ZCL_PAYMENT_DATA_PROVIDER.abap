*&---------------------------------------------------------------------*
*& Class ZCL_PAYMENT_DATA_PROVIDER
*&---------------------------------------------------------------------*
CLASS zcl_payment_data_provider DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS get_payment_overview
      RETURNING VALUE(rt_items) TYPE zcl_payment_entity=>ty_payment_items .

  PRIVATE SECTION.

    METHODS get_mock_vendor_master
      RETURNING VALUE(rt_vendors) TYPE zcl_payment_entity=>ty_vendor_master_tab .

    METHODS get_mock_open_items
      RETURNING VALUE(rt_items) TYPE zcl_payment_entity=>ty_open_item_tab .

    METHODS determine_status
      IMPORTING iv_due_date     TYPE dats
      EXPORTING ev_days_overdue TYPE i
                ev_status       TYPE string
                ev_status_text  TYPE string .

ENDCLASS.



CLASS zcl_payment_data_provider IMPLEMENTATION.


  METHOD get_payment_overview.

    DATA(lt_vendors) = get_mock_vendor_master( ).
    DATA(lt_items)   = get_mock_open_items( ).

    "   SELECT a~lifnr, b~name1, a~belnr, a~dmbtr, a~waers, a~net_due_date
    "     FROM bsik AS a
    "     INNER JOIN lfb1 AS b ON b~lifnr = a~lifnr
    "    WHERE a~bukrs = '1000'.
    LOOP AT lt_items INTO DATA(ls_item).
      READ TABLE lt_vendors INTO DATA(ls_vendor) WITH KEY lifnr = ls_item-lifnr.
      IF sy-subrc <> 0.
        CONTINUE. " Orphan open item without a vendor master - skip defensively.
      ENDIF.

      DATA(ls_result) = VALUE zcl_payment_entity=>ty_payment_item(
        vendor_id   = ls_item-lifnr
        vendor_name = ls_vendor-name1
        invoice_no  = ls_item-belnr
        amount      = ls_item-dmbtr
        currency    = ls_item-waers
        due_date    = ls_item-net_due_date ).

      determine_status(
        EXPORTING
          iv_due_date     = ls_item-net_due_date
        IMPORTING
          ev_days_overdue = ls_result-days_overdue
          ev_status       = ls_result-status
          ev_status_text  = ls_result-status_text ).

      APPEND ls_result TO rt_items.
    ENDLOOP.

    SORT rt_items BY days_overdue DESCENDING.

  ENDMETHOD.


  METHOD determine_status.

    ev_days_overdue = sy-datum - iv_due_date.

    IF ev_days_overdue > zcl_payment_entity=>gc_critical_threshold.
      ev_status      = zcl_payment_entity=>gc_status-critical.
      ev_status_text = |Critical ({ ev_days_overdue } days overdue)|.

    ELSEIF ev_days_overdue > 0.
      ev_status      = zcl_payment_entity=>gc_status-warning.
      ev_status_text = |Warning ({ ev_days_overdue } days overdue)|.

    ELSE.
      ev_status       = zcl_payment_entity=>gc_status-on_time.
      ev_days_overdue = 0. 
      ev_status_text  = 'On Time'.
    ENDIF.

  ENDMETHOD.


  METHOD get_mock_vendor_master.

    " Simulates: SELECT * FROM lfb1 WHERE bukrs = '1000'.
    rt_vendors = VALUE #(
      ( lifnr = '0000100001' name1 = 'Bosch GmbH'           bukrs = '1000' akont = '0000160000' )
      ( lifnr = '0000100002' name1 = 'Siemens AG'           bukrs = '1000' akont = '0000160000' )
      ( lifnr = '0000100003' name1 = 'Continental AG'       bukrs = '1000' akont = '0000160000' )
      ( lifnr = '0000100004' name1 = 'BASF SE'              bukrs = '1000' akont = '0000160000' )
      ( lifnr = '0000100005' name1 = 'ThyssenKrupp AG'      bukrs = '1000' akont = '0000160000' )
      ( lifnr = '0000100006' name1 = 'Allianz SE'           bukrs = '1000' akont = '0000160000' )
      ( lifnr = '0000100007' name1 = 'Deutsche Telekom AG'  bukrs = '1000' akont = '0000160000' )
      ( lifnr = '0000100008' name1 = 'Henkel AG & Co. KGaA' bukrs = '1000' akont = '0000160000' )
    ).

  ENDMETHOD.


  METHOD get_mock_open_items.
    DATA(lv_today) = sy-datum.

    rt_items = VALUE #(
      ( lifnr = '0000100001' belnr = '1900000001' gjahr = '2026' bldat = lv_today - 75 dmbtr = '15750.00' waers = 'EUR' net_due_date = lv_today - 45 augbl = '' )
      ( lifnr = '0000100002' belnr = '1900000002' gjahr = '2026' bldat = lv_today - 60 dmbtr = '8200.50'  waers = 'EUR' net_due_date = lv_today - 31 augbl = '' )
      ( lifnr = '0000100003' belnr = '1900000003' gjahr = '2026' bldat = lv_today - 40 dmbtr = '4300.00'  waers = 'EUR' net_due_date = lv_today - 15 augbl = '' )
      ( lifnr = '0000100004' belnr = '1900000004' gjahr = '2026' bldat = lv_today - 35 dmbtr = '12990.75' waers = 'USD' net_due_date = lv_today - 5  augbl = '' )
      ( lifnr = '0000100005' belnr = '1900000005' gjahr = '2026' bldat = lv_today - 20 dmbtr = '2150.00'  waers = 'EUR' net_due_date = lv_today - 1  augbl = '' )
      ( lifnr = '0000100006' belnr = '1900000006' gjahr = '2026' bldat = lv_today - 10 dmbtr = '6700.00'  waers = 'EUR' net_due_date = lv_today + 5  augbl = '' )
      ( lifnr = '0000100007' belnr = '1900000007' gjahr = '2026' bldat = lv_today - 5  dmbtr = '975.20'   waers = 'EUR' net_due_date = lv_today + 14 augbl = '' )
      ( lifnr = '0000100008' belnr = '1900000008' gjahr = '2026' bldat = lv_today - 2  dmbtr = '3300.00'  waers = 'USD' net_due_date = lv_today + 30 augbl = '' )
    ).

  ENDMETHOD.


ENDCLASS.
