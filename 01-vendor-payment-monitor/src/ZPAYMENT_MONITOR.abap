*&---------------------------------------------------------------------*
*& Report ZPAYMENT_MONITOR
*&---------------------------------------------------------------------*
REPORT zpayment_monitor.

DATA go_monitor   TYPE REF TO zcl_payment_monitor.
DATA gv_filter    TYPE string.
DATA gv_displayed TYPE abap_bool.

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-001.
PARAMETERS:
  p_all  RADIOBUTTON GROUP g1 DEFAULT 'X',
  p_crit RADIOBUTTON GROUP g1,
  p_warn RADIOBUTTON GROUP g1,
  p_ont  RADIOBUTTON GROUP g1.
SELECTION-SCREEN END OF BLOCK b01.

START-OF-SELECTION.
  gv_filter = COND #(
    WHEN p_crit = abap_true THEN zcl_payment_monitor=>gc_filter-critical
    WHEN p_warn = abap_true THEN zcl_payment_monitor=>gc_filter-warning
    WHEN p_ont  = abap_true THEN zcl_payment_monitor=>gc_filter-on_time
    ELSE                         zcl_payment_monitor=>gc_filter-all ).

  go_monitor = NEW zcl_payment_monitor( ).

  CALL SCREEN 100.

*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS100'.
  SET TITLEBAR 'TITLE100'.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  DISPLAY_ALV_0100  OUTPUT
*&---------------------------------------------------------------------*
MODULE display_alv_0100 OUTPUT.

  IF gv_displayed = abap_false.
    go_monitor->run( gv_filter ).
    gv_displayed = abap_true.
  ENDIF.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      gv_displayed = abap_false.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
