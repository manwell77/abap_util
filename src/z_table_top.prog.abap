*&---------------------------------------------------------------------*
*&  Include           Z_TABLE_TOP
*&---------------------------------------------------------------------*

* Global types
TYPES:
  tt_string                     TYPE STANDARD TABLE OF string,

  BEGIN OF st_date_format,
    datfm    TYPE xudatfm,
    text     TYPE char10,
  END OF st_date_format,
  tt_date_format TYPE STANDARD TABLE OF st_date_format,

  BEGIN OF st_decimal_format,
    decfm TYPE xudcpfm,
    text  TYPE char12,
  END OF st_decimal_format,
  tt_decimal_format TYPE STANDARD TABLE OF st_decimal_format.


* Global data
DATA:

* Screen field
  ##NEEDED
  i_table_struct                TYPE tabname16,
  i_table_struct_d              TYPE tabname16,
  i_file_path                   TYPE string,
  i_file_path_d                 TYPE string,
  tab_separator                 TYPE char1,
  default                       TYPE char1,
  selected_separator            TYPE char1       VALUE ';',
  with_header                   TYPE char1       VALUE 'X',
  with_header_d                 TYPE char1,
  ok_code                       TYPE ok,
  rb_insert                     TYPE char1,
  rb_modify                     TYPE char1,
  custom_date_flag              TYPE char1,
  custom_date_format            TYPE char10,
  custom_decimal_flag           TYPE char1,
  custom_decimal_format         TYPE char12,
  custom_date_flag_d            TYPE char1,
  custom_date_format_d          TYPE char10,
  custom_decimal_flag_d         TYPE char1,
  custom_decimal_format_d       TYPE char12,

* Search help for format conversion
  ##NEEDED
  gt_decimal_format             TYPE tt_decimal_format,
  ##NEEDED
  gt_date_format                TYPE tt_date_format,
  ##NEEDED
  gt_decimal_format_d           TYPE tt_decimal_format,
  ##NEEDED
  gt_date_format_d              TYPE tt_date_format.


*&SPWIZARD: FUNCTION CODES FOR TABSTRIP 'TABLE_STRIP'
CONSTANTS: BEGIN OF c_table_strip,
             tab1 LIKE sy-ucomm VALUE 'TABLE_STRIP_FC1',
             tab2 LIKE sy-ucomm VALUE 'TABLE_STRIP_FC2',
           END OF c_table_strip.
*&SPWIZARD: DATA FOR TABSTRIP 'TABLE_STRIP'
CONTROLS:  table_strip TYPE TABSTRIP.
DATA:      BEGIN OF g_table_strip,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE 'Z_TABLE',
             pressed_tab LIKE sy-ucomm VALUE c_table_strip-tab1,
           END OF g_table_strip.
