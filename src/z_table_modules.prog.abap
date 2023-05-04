*&---------------------------------------------------------------------*
*&  Include           Z_TABLE_MODULES
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  PBO_9000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_9000 OUTPUT.

  SET PF-STATUS 'STATUS_9000'.
  SET TITLEBAR 'TITLE_9000'.

ENDMODULE.                 " PBO_9000  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  PBO_9002  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
##NEEDED
MODULE pbo_9002 OUTPUT.

ENDMODULE.                 " PBO_9002  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  pbo_9001  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
##NEEDED
MODULE pbo_9001 OUTPUT.

ENDMODULE.                 " pbo_9001  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  PAI_9000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
##NEEDED
MODULE pai_9000 INPUT.

ENDMODULE.                 " PAI_9000  INPUT

*&---------------------------------------------------------------------*
*&      Module  pai_9001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_9001 INPUT.
  ##DECL_MODUL ##NEEDED
  DATA : lv_ok_code TYPE ok VALUE IS INITIAL.

  CLEAR lv_ok_code.
  MOVE ok_code TO lv_ok_code.
  CLEAR ok_code.

  CASE lv_ok_code.

    WHEN 'UPLOAD'.
      CLEAR lv_ok_code.
      PERFORM upload.

    WHEN 'EXIT' OR 'BACK'.
      CLEAR lv_ok_code.
      LEAVE PROGRAM.

    WHEN 'FILE_OPEN'.
      CLEAR lv_ok_code.
      PERFORM open_file CHANGING i_file_path.

    WHEN 'TABLE_STRIP_FC1'.
      CLEAR lv_ok_code.
      g_table_strip-pressed_tab = 'TABLE_STRIP_FC1'.

    WHEN 'TABLE_STRIP_FC2'.
      CLEAR lv_ok_code.
      g_table_strip-pressed_tab = 'TABLE_STRIP_FC2'.

  ENDCASE.

ENDMODULE.                 " pai_9001  INPUT

*&---------------------------------------------------------------------*
*&      Module  PAI_9002  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_9002 INPUT.

  IF ok_code IS NOT INITIAL.
    MOVE ok_code TO lv_ok_code.
    CLEAR ok_code.
  ENDIF.


  CASE lv_ok_code.

    WHEN 'DOWNLOAD'.
      CLEAR lv_ok_code.
      PERFORM download_table.
    WHEN 'EXIT' OR 'BACK'.
      CLEAR lv_ok_code.
      LEAVE PROGRAM.
    WHEN 'FILE_SAVE'.
      CLEAR lv_ok_code.
      PERFORM save_file_dialog.
    WHEN 'TABLE_STRIP_FC1'.
      CLEAR lv_ok_code.
      g_table_strip-pressed_tab = 'TABLE_STRIP_FC1'.
    WHEN 'TABLE_STRIP_FC2'.
      CLEAR lv_ok_code.
      g_table_strip-pressed_tab = 'TABLE_STRIP_FC2'.
  ENDCASE.


  CLEAR lv_ok_code.

ENDMODULE.                 " PAI_9002  INPUT


*&SPWIZARD: OUTPUT MODULE FOR TS 'TABLE_STRIP'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: SETS ACTIVE TAB
MODULE table_strip_active_tab_set OUTPUT.
  table_strip-activetab = g_table_strip-pressed_tab.
  CASE g_table_strip-pressed_tab.
    WHEN c_table_strip-tab1.
      g_table_strip-subscreen = '9001'.
    WHEN c_table_strip-tab2.
      g_table_strip-subscreen = '9002'.
    WHEN OTHERS.
*&SPWIZARD:      DO NOTHING
  ENDCASE.
ENDMODULE.                    "TABLE_STRIP_ACTIVE_TAB_SET OUTPUT

*&SPWIZARD: INPUT MODULE FOR TS 'TABLE_STRIP'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GETS ACTIVE TAB
MODULE table_strip_active_tab_get INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN c_table_strip-tab1.
      g_table_strip-pressed_tab = c_table_strip-tab1.
    WHEN c_table_strip-tab2.
      g_table_strip-pressed_tab = c_table_strip-tab2.
    WHEN OTHERS.
*&SPWIZARD:      DO NOTHING

  ENDCASE.

* aggiunta
  CLEAR ok_code.

ENDMODULE.                    "TABLE_STRIP_ACTIVE_TAB_GET INPUT
*&---------------------------------------------------------------------*
*&      Module  custom_date_format_f4_help  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE custom_date_format_f4_help INPUT.
  PERFORM custom_date_format_f4_help.
ENDMODULE.                 " custom_date_format_f4_help  INPUT
*&---------------------------------------------------------------------*
*&      Module  custom_decimal_format_f4_help  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE custom_decimal_format_f4_help INPUT.
  PERFORM custom_decimal_format_f4_help.
ENDMODULE.                 " custom_decimal_format_f4_help  INPUT
*&---------------------------------------------------------------------*
*&      Module  custom_date_format_d_f4_help  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE custom_date_format_d_f4_help INPUT.
  PERFORM custom_date_format_d_f4_help.
ENDMODULE.                 " custom_date_format_d_f4_help  INPUT
*&---------------------------------------------------------------------*
*&      Module  custom_dec_format_d_f4_help  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE custom_dec_format_d_f4_help INPUT.
  PERFORM custom_dec_format_d_f4_help.
ENDMODULE.                 " custom_dec_format_d_f4_help  INPUT
