*&---------------------------------------------------------------------*
*& Class ZCL_PAYMENT_ALV_DISPLAY
*&---------------------------------------------------------------------*
CLASS zcl_payment_alv_display DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS display
      IMPORTING it_data TYPE zcl_payment_entity=>ty_payment_items .

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_alv_line.
        INCLUDE TYPE zcl_payment_entity=>ty_payment_item.
    TYPES:
        row_color TYPE char3,
      END OF ty_alv_line .
    TYPES ty_alv_lines TYPE STANDARD TABLE OF ty_alv_line WITH EMPTY KEY .

    CONSTANTS gc_excel_fcode TYPE ui_func VALUE 'EXCEL_EXPORT' .

    DATA mo_container TYPE REF TO cl_gui_custom_container .
    DATA mo_grid       TYPE REF TO cl_gui_alv_grid .
    DATA mt_alv_data   TYPE ty_alv_lines .

    METHODS build_alv_data
      IMPORTING it_data       TYPE zcl_payment_entity=>ty_payment_items
      RETURNING VALUE(rt_alv) TYPE ty_alv_lines .

    METHODS build_fieldcatalog
      RETURNING VALUE(rt_fcat) TYPE lvc_t_fcat .

    METHODS add_fcat_entry
      IMPORTING iv_fieldname   TYPE lvc_s_fcat-fieldname
                iv_text        TYPE string
                iv_outputlen   TYPE lvc_s_fcat-outputlen DEFAULT 0
                iv_col_pos     TYPE lvc_s_fcat-col_pos
                iv_cfieldname  TYPE lvc_s_fcat-cfieldname OPTIONAL
                iv_do_sum      TYPE lvc_s_fcat-do_sum OPTIONAL
      RETURNING VALUE(rs_fcat) TYPE lvc_s_fcat .

    METHODS build_layout
      RETURNING VALUE(rs_layout) TYPE lvc_s_layo .

    METHODS register_events .

    METHODS export_to_excel .

    METHODS on_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object .

    METHODS on_user_command
        FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm .

ENDCLASS.



CLASS zcl_payment_alv_display IMPLEMENTATION.


  METHOD display.

    IF mo_container IS NOT BOUND.
      mo_container = NEW cl_gui_custom_container( container_name = 'ALV_CONTAINER' ).
      mo_grid       = NEW cl_gui_alv_grid( i_parent = mo_container ).
      register_events( ).
    ENDIF.

    mt_alv_data = build_alv_data( it_data ).

    DATA(lt_fcat)   = build_fieldcatalog( ).
    DATA(ls_layout) = build_layout( ).

    mo_grid->set_table_for_first_display(
      EXPORTING
        is_layout       = ls_layout
      CHANGING
        it_outtab       = mt_alv_data
        it_fieldcatalog = lt_fcat ).

  ENDMETHOD.


  METHOD build_alv_data.

    LOOP AT it_data INTO DATA(ls_item).
      DATA(ls_alv) = CORRESPONDING ty_alv_line( ls_item ).

      ls_alv-row_color = SWITCH char3( ls_item-status
        WHEN zcl_payment_entity=>gc_status-critical THEN 'C61' " red, intensified
        WHEN zcl_payment_entity=>gc_status-warning  THEN 'C31' " yellow, intensified
        WHEN zcl_payment_entity=>gc_status-on_time  THEN 'C51' " green, intensified
        ELSE '' ).

      APPEND ls_alv TO rt_alv.
    ENDLOOP.

  ENDMETHOD.


  METHOD add_fcat_entry.

    rs_fcat-fieldname  = iv_fieldname.
    rs_fcat-scrtext_l  = iv_text.
    rs_fcat-scrtext_m  = iv_text.
    rs_fcat-scrtext_s  = iv_text.
    rs_fcat-reptext    = iv_text.
    rs_fcat-outputlen  = iv_outputlen.
    rs_fcat-col_pos    = iv_col_pos.
    rs_fcat-cfieldname = iv_cfieldname.
    rs_fcat-do_sum     = iv_do_sum.

  ENDMETHOD.


  METHOD build_fieldcatalog.
    rt_fcat = VALUE lvc_t_fcat(
      ( add_fcat_entry( iv_fieldname = 'VENDOR_ID'    iv_text = 'Vendor'       iv_outputlen = 10 iv_col_pos = 1 ) )
      ( add_fcat_entry( iv_fieldname = 'VENDOR_NAME'  iv_text = 'Vendor Name'  iv_outputlen = 25 iv_col_pos = 2 ) )
      ( add_fcat_entry( iv_fieldname = 'INVOICE_NO'   iv_text = 'Invoice No.'  iv_outputlen = 12 iv_col_pos = 3 ) )
      ( add_fcat_entry( iv_fieldname = 'AMOUNT'       iv_text = 'Amount'       iv_outputlen = 15 iv_col_pos = 4
                         iv_cfieldname = 'CURRENCY' iv_do_sum = abap_true ) )
      ( add_fcat_entry( iv_fieldname = 'CURRENCY'     iv_text = 'Cur.'         iv_outputlen = 5  iv_col_pos = 5 ) )
      ( add_fcat_entry( iv_fieldname = 'DUE_DATE'     iv_text = 'Due Date'     iv_outputlen = 10 iv_col_pos = 6 ) )
      ( add_fcat_entry( iv_fieldname = 'DAYS_OVERDUE' iv_text = 'Days Overdue' iv_outputlen = 12 iv_col_pos = 7 ) )
      ( add_fcat_entry( iv_fieldname = 'STATUS_TEXT'  iv_text = 'Status'       iv_outputlen = 30 iv_col_pos = 8 ) )
    ).

  ENDMETHOD.


  METHOD build_layout.

    rs_layout-info_fname = 'ROW_COLOR'.
    rs_layout-zebra      = abap_true.
    rs_layout-cwidth_opt = abap_true.
    rs_layout-sel_mode   = 'A'.

  ENDMETHOD.


  METHOD register_events.

    SET HANDLER on_toolbar      FOR mo_grid.
    SET HANDLER on_user_command FOR mo_grid.

  ENDMETHOD.


  METHOD on_toolbar.

    APPEND VALUE stb_button( butn_type = 3 ) TO e_object->mt_toolbar.

    APPEND VALUE stb_button(
      function  = gc_excel_fcode
      icon      = icon_xxl_export
      quickinfo = 'Export the displayed list to Microsoft Excel'
      text      = 'Export to Excel'
      butn_type = 0 ) TO e_object->mt_toolbar.

  ENDMETHOD.


  METHOD on_user_command.

    CASE e_ucomm.
      WHEN gc_excel_fcode.
        export_to_excel( ).
    ENDCASE.

  ENDMETHOD.


  METHOD export_to_excel.

    DATA lv_fullpath TYPE string.
    DATA lv_path     TYPE string.
    DATA lv_filename TYPE string.
    DATA lt_raw      TYPE TABLE OF string.

    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING
        window_title       = 'Export Vendor Payment Monitor'
        default_extension  = 'XLSX'
        default_file_name  = 'vendor_payment_monitor'
        file_filter        = 'Excel Files (*.XLSX)|*.XLSX|All Files (*.*)|*.*'
      CHANGING
        filename           = lv_filename
        path               = lv_path
        fullpath           = lv_fullpath
      EXCEPTIONS
        OTHERS             = 1 ).

    IF sy-subrc <> 0 OR lv_fullpath IS INITIAL.
      RETURN. 
    ENDIF.

    DATA(lv_tab) = cl_abap_char_utilities=>horizontal_tab.

    APPEND |Vendor{ lv_tab }Vendor Name{ lv_tab }Invoice No.{ lv_tab }Amount{ lv_tab }| &&
           |Currency{ lv_tab }Due Date{ lv_tab }Days Overdue{ lv_tab }Status| TO lt_raw.

    LOOP AT mt_alv_data INTO DATA(ls_row).
      APPEND |{ ls_row-vendor_id }{ lv_tab }{ ls_row-vendor_name }{ lv_tab }{ ls_row-invoice_no }{ lv_tab }| &&
             |{ ls_row-amount DECIMALS = 2 }{ lv_tab }{ ls_row-currency }{ lv_tab }{ ls_row-due_date DATE = USER }{ lv_tab }| &&
             |{ ls_row-days_overdue }{ lv_tab }{ ls_row-status_text }| TO lt_raw.
    ENDLOOP.

    cl_gui_frontend_services=>gui_download(
      EXPORTING
        filename = lv_fullpath
        filetype = 'ASC'
        codepage = '4110'
      CHANGING
        data_tab = lt_raw
      EXCEPTIONS
        OTHERS   = 24 ).

    IF sy-subrc <> 0.
      MESSAGE 'Export to Excel failed' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.
      MESSAGE 'Export completed successfully' TYPE 'S'.
    ENDIF.

  ENDMETHOD.


ENDCLASS.
