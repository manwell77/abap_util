*&---------------------------------------------------------------------*
*& Report  ZMSGTRANSLATION
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

include zmsgtranslationtop.

selection-screen begin of block bl_1 with frame title text-001.

parameters: p_msgid type arbgb obligatory.

parameters: p_from type spras obligatory,
            p_to   type spras obligatory.

select-options: so_msg for gs_message-msgnr.

selection-screen end of block bl_1.

initialization.

  gv_title_9001        = text-002.

  gs_layout-zebra      = 'X'.
  gs_layout-sel_mode   = 'D'.

start-of-selection.

  perform get_and_convert_fcat using '9001' 'ZMSGTRANS_S' p_from p_to changing gt_fcat_9001 gv_subrc.

  if gv_subrc ne 0.
    message e010(zutil) with 'ZMSGTRANS_S'.
  endif.

  perform get_message using p_msgid p_from so_msg[] changing gt_from.

  perform get_message using p_msgid p_to   so_msg[] changing gt_to.

  perform build_mix using p_from p_to gt_from gt_to changing gt_mix.

  call screen 9001.

  include zmsgtranslationf01.

  include zmsgtranslationm01.
