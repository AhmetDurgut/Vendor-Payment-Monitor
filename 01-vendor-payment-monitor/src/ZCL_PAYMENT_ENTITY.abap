*&---------------------------------------------------------------------*
*& Class ZCL_PAYMENT_ENTITY
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
CLASS zcl_payment_entity DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    CONSTANTS:
      BEGIN OF gc_status,
        critical TYPE string VALUE 'CRITICAL',
        warning  TYPE string VALUE 'WARNING',
        on_time  TYPE string VALUE 'ON_TIME',
      END OF gc_status .

    CONSTANTS gc_critical_threshold TYPE i VALUE 30 .

    TYPES:
      BEGIN OF ty_vendor_master,
        lifnr TYPE lifnr,   
        name1 TYPE name1_gp, 
        bukrs TYPE bukrs,    
        akont TYPE hkont,    
      END OF ty_vendor_master .
    TYPES ty_vendor_master_tab TYPE STANDARD TABLE OF ty_vendor_master WITH EMPTY KEY .

    TYPES:
      BEGIN OF ty_open_item,
        lifnr        TYPE lifnr,    
        belnr        TYPE belnr_d,   
        gjahr        TYPE gjahr,     
        bldat        TYPE bldat,     
        dmbtr        TYPE dmbtr,     
        waers        TYPE waers,    
        net_due_date TYPE dats,     
        augbl        TYPE belnr_d,   
      END OF ty_open_item .
    TYPES ty_open_item_tab TYPE STANDARD TABLE OF ty_open_item WITH EMPTY KEY .

    TYPES:
      BEGIN OF ty_payment_item,
        vendor_id    TYPE lifnr,
        vendor_name  TYPE name1_gp,
        invoice_no   TYPE belnr_d,
        amount       TYPE dmbtr,
        currency     TYPE waers,
        due_date     TYPE dats,
        days_overdue TYPE i,
        status       TYPE string,  
        status_text  TYPE string,  
      END OF ty_payment_item .
    TYPES ty_payment_items TYPE STANDARD TABLE OF ty_payment_item WITH EMPTY KEY .

ENDCLASS.



CLASS zcl_payment_entity IMPLEMENTATION.
ENDCLASS.
