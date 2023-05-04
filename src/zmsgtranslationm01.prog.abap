*&---------------------------------------------------------------------*
*&  Include           ZMSGTRANSLATIONM01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  status_9001  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module status_9001 output.

  set pf-status 'GUI_STATUS_9001'.

  gs_exclude = cl_gui_alv_grid=>mc_fc_loc_cut.
  append gs_exclude to gt_exclude.

  gs_exclude = cl_gui_alv_grid=>mc_fc_loc_copy.
  append gs_exclude to gt_exclude.

  gs_exclude = cl_gui_alv_grid=>mc_fc_loc_undo.
  append gs_exclude to gt_exclude.

  gs_exclude = cl_gui_alv_grid=>mc_fc_loc_append_row.
  append gs_exclude to gt_exclude.

  gs_exclude = cl_gui_alv_grid=>mc_fc_loc_insert_row.
  append gs_exclude to gt_exclude.

  gs_exclude = cl_gui_alv_grid=>mc_fc_loc_delete_row.
  append gs_exclude to gt_exclude.

  gs_exclude = cl_gui_alv_grid=>mc_fc_loc_copy_row.
  append gs_exclude to gt_exclude.

  perform alv_build  using 'GUI_TITLE_9001' gv_title_9001 'CCONT_9001' changing go_container go_alv gs_layout.

  try.

      go_alv->set_table_for_first_display( exporting
                                             i_structure_name     = 'ZMSGTRANS_S'
                                             is_layout            = gs_layout
                                             it_toolbar_excluding = gt_exclude
                                           changing
                                             it_outtab            = gt_mix
                                             it_fieldcatalog      = gt_fcat_9001
                                             it_sort              = gt_sort ).

  endtry.

endmodule.
*&---------------------------------------------------------------------*
*&      Module  user_command_9001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module user_command_9001 input.

  case sy-ucomm.

    when 'BACK' or 'CANCEL' or 'EXIT'.

      try.

        perform alv_destroy changing go_alv go_container.

      endtry.

     leave to screen 0.

   when 'SAVE'.

    go_alv->check_changed_data( ).

    refresh: gt_from, gt_to.

    perform build_new using gt_mix changing gt_from gt_to.

    modify t100 from table gt_from.

    modify t100 from table gt_to.

    message s011(zutil).

  endcase.

endmodule.

*&---------------------------------------------------------------------*
*&      Module  exit_9001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module exit_9001 input.
  leave program.
endmodule.
