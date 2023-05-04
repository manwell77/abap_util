*&---------------------------------------------------------------------*
*& Report  ZSE16N
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

include zse16ntop.

initialization.

  gv_title_9001        = text-002.

  gs_layout-zebra      = 'X'.
  gs_layout-sel_mode   = 'D'.
  gs_layout-cwidth_opt = 'X'.

start-of-selection.

* render
  call screen 9000.

  include zse16nf01.
  include zse16nm01.
