*&---------------------------------------------------------------------*
*& Report  Z_TABLE
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT   z_table.

INCLUDE: z_table_top,
         z_table_modules,
         z_table_form.


START-OF-SELECTION.

* go to main screen
  CALL SCREEN 9000.
