*&---------------------------------------------------------------------*
*& Include          ZACTTYPE_FRA_DATA
*&---------------------------------------------------------------------*
TYPES:

  BEGIN OF  ts_act,
    kokrs   TYPE csla-kokrs,
    spras   TYPE cslt-spras,
    lstar   TYPE csla-lstar,
    datab   TYPE csla-datab,
    datbi   TYPE csla-datbi,
    leinh   TYPE csla-leinh,
    meinh1  TYPE t006i-isocode,
    kstty   TYPE csla-kstty,
    latyp   TYPE csla-latyp,
    vksta   TYPE csla-vksta,
    tarkz   TYPE csla-tarkz,
    yrate   TYPE csla-yrate,
    fixvo   TYPE csla-fixvo,
    manist  TYPE csla-manist,
    latypi  TYPE csla-latypi,
    tarkz_i TYPE csla-tarkz_i,
    sprkz   TYPE csla-sprkz,
    auseh   TYPE csla-auseh,
    meinh2  TYPE t006i-isocode,
    ausfk   TYPE csla-ausfk,
    ktext   TYPE cslt-ktext,
    ltext   TYPE cslt-ltext,
    manplan TYPE csla-manplan,
  END OF  ts_act,

  BEGIN OF ts_check,
    spras TYPE cslt-spras,
    kokrs TYPE cslt-kokrs,
    lstar TYPE cslt-lstar,
    datbi TYPE cslt-datbi,
  END OF ts_check,

  BEGIN OF ts_heading,
    text TYPE char30,
  END OF ts_heading.

DATA: gt_act     TYPE STANDARD TABLE OF ts_act,
      gt_crea    TYPE STANDARD TABLE OF ts_act,
      gt_mod     TYPE STANDARD TABLE OF ts_act,
      gt_heading TYPE STANDARD TABLE OF ts_heading,
      gt_logs    TYPE STANDARD TABLE OF bapiret2,
      gv_flag    TYPE c.

CONSTANTS: c_flag_crea TYPE c VALUE 'C',
           c_flag_mod  TYPE c VALUE 'M',
           c_msg_e     TYPE c VALUE 'E',
           c_msg_i     TYPE c VALUE 'I',
           c_msg_x     TYPE c VALUE 'X',
           c_msg_a     TYPE c VALUE 'A'.
