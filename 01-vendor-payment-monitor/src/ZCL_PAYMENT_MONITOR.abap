*&---------------------------------------------------------------------*
*& Class ZCL_PAYMENT_MONITOR
*&---------------------------------------------------------------------*
CLASS zcl_payment_monitor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS:
      BEGIN OF gc_filter,
        all      TYPE string VALUE 'ALL',
        critical TYPE string VALUE 'CRITICAL',
        warning  TYPE string VALUE 'WARNING',
        on_time  TYPE string VALUE 'ON_TIME',
      END OF gc_filter .

    METHODS constructor .

    METHODS run
      IMPORTING iv_status_filter TYPE string DEFAULT gc_filter-all .

  PRIVATE SECTION.

    DATA mo_data_provider TYPE REF TO zcl_payment_data_provider .
    DATA mo_alv_display   TYPE REF TO zcl_payment_alv_display .

    METHODS apply_status_filter
      IMPORTING iv_status_filter TYPE string
                it_data          TYPE zcl_payment_entity=>ty_payment_items
      RETURNING VALUE(rt_data)   TYPE zcl_payment_entity=>ty_payment_items .

ENDCLASS.



CLASS zcl_payment_monitor IMPLEMENTATION.


  METHOD constructor.

    mo_data_provider = NEW zcl_payment_data_provider( ).
    mo_alv_display   = NEW zcl_payment_alv_display( ).

  ENDMETHOD.


  METHOD run.

    DATA(lt_overview) = mo_data_provider->get_payment_overview( ).

    DATA(lt_filtered) = apply_status_filter(
      iv_status_filter = iv_status_filter
      it_data          = lt_overview ).

    IF lt_filtered IS INITIAL.
      MESSAGE 'No vendor payment items found for the selected filter' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    mo_alv_display->display( lt_filtered ).

  ENDMETHOD.


  METHOD apply_status_filter.

    IF iv_status_filter IS INITIAL OR iv_status_filter = gc_filter-all.
      rt_data = it_data.
      RETURN.
    ENDIF.
    LOOP AT it_data INTO DATA(ls_item) WHERE status = iv_status_filter.
      APPEND ls_item TO rt_data.
    ENDLOOP.

  ENDMETHOD.


ENDCLASS.
