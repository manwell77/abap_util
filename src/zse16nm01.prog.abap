*&---------------------------------------------------------------------*
*&  Include           ZSE16NM01
*&---------------------------------------------------------------------*
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

  assign go_data->* to <gt_data>.

  try.

      go_alv->set_table_for_first_display( exporting
                                             is_layout                     = gs_layout
                                             it_toolbar_excluding          = gt_exclude
                                           changing
                                             it_outtab                     = <gt_data>
                                             it_fieldcatalog               = gt_fcat_9001
                                             it_sort                       = gt_sort
                                           exceptions
                                             invalid_parameter_combination = 1
                                             program_error                 = 2
                                             too_many_lines                = 3
                                             others                        = 4 ).

      if sy-subrc ne 0. message e017(zutil). endif.

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

      set screen gc_9000.

    when 'SAVE'.

      go_alv->check_changed_data( ).

      modify (gv_tabname) from table <gt_data>.

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
*&---------------------------------------------------------------------*
*&      Module  STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module status_9000 output.

  set pf-status 'GUI_STATUS_9000'.

  if not go_area is bound.

    create object go_area
      exporting
        container_name              = 'TEXTAREA'
      exceptions
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.

  endif.

  if not go_editor is bound.

    create object go_editor
      exporting
        parent                     = go_area
        wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
        wordwrap_position          = gc_line
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true.

  endif.

endmodule.                 " STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module user_command_9000 input.

  case sy-ucomm.

    when 'BACK' or 'CANCEL' or 'EXIT'.

      leave to screen 0.

    when 'SRC'.

      refresh: gt_query. clear: gv_query.

      go_editor->get_text_as_r3table( importing table = gt_query ).

      loop at gt_query into gv_tmp.
        replace all occurrences of cl_abap_char_utilities=>cr_lf in gv_tmp with space.
        gv_query = |{ gv_query } { gv_tmp }|.
      endloop.

      condense gv_query.

      if sy-subrc ne 0. message e016(zutil). endif.

*     get data
      perform get_data using gv_tabname gv_query changing go_data gv_subrc.
      if gv_subrc ne 0. message e016(zutil). endif.

*     build fieldcatalog
      perform get_and_convert_fcat using gv_tabname go_data changing gt_fcat_9001 gv_subrc.
      if gv_subrc ne 0. message e010(zutil) with gv_tabname. endif.

*     render
      set screen gc_9001.

  endcase.

endmodule.                 " USER_COMMAND_9000  INPUT
