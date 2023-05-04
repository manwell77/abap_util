*&---------------------------------------------------------------------*
*&  Include           ZMSGTRANSLATIONF01
*&---------------------------------------------------------------------*

form get_and_convert_fcat using  value(v_screen)    type numc4
                                 value(v_structure) type tabname
                                 value(v_from)      type spras
                                 value(v_to)        type spras

                          changing  c_fcat          type lvc_t_fcat
                                    c_subrc         type sysubrc.

  data: lv_colpos    type lvc_colpos,
        lv_from      type sptxt,
        lv_to        type sptxt,
        ls_fcat_to   type lvc_s_fcat,
        ls_fcat_from type slis_fieldcat_alv,
        lt_fcat_from type slis_t_fieldcat_alv.

  field-symbols: <lfs_fcat>   type lvc_s_fcat.

  clear c_subrc.

  call function 'REUSE_ALV_FIELDCATALOG_MERGE'
    exporting
      i_structure_name             = v_structure
    changing
      ct_fieldcat                  = lt_fcat_from
    exceptions
      inconsistent_interface       = 1
      program_error                = 2
      others                       = 3.

  if sy-subrc ne 0.
    add sy-subrc to c_subrc.
    return.
  endif.

  loop at lt_fcat_from into ls_fcat_from.
    move-corresponding ls_fcat_from to ls_fcat_to.
    append ls_fcat_to to c_fcat.
    clear: ls_fcat_from, ls_fcat_to.
  endloop.

  select single sptxt from t002t into lv_from where spras eq v_from and sprsl eq v_from.
  if sy-subrc ne 0.
    add sy-subrc to c_subrc.
    return.
  endif.

  select single sptxt from t002t into lv_to where spras eq v_to and sprsl eq v_to.
  if sy-subrc ne 0.
    add sy-subrc to c_subrc.
    return.
  endif.

  case v_screen.

    when '9001'.

      loop at c_fcat assigning <lfs_fcat>.

        add 1 to lv_colpos.

        case <lfs_fcat>-fieldname.

          when 'ARBGB'.
            <lfs_fcat>-col_pos = lv_colpos.
            <lfs_fcat>-seltext = text-003.
            <lfs_fcat>-coltext = text-003.

          when 'MSGNR'.
            <lfs_fcat>-col_pos = lv_colpos.
            <lfs_fcat>-seltext = text-004.
            <lfs_fcat>-coltext = text-004.

          when 'SPRSL_FROM'.
            <lfs_fcat>-no_out  = 'X'.
            subtract 1 from lv_colpos.

          when 'TEXT_FROM'.
            <lfs_fcat>-col_pos = lv_colpos.
            <lfs_fcat>-edit    = 'X'.
            <lfs_fcat>-seltext = lv_from.
            <lfs_fcat>-coltext = lv_from.

          when 'SPRSL_TO'.
            <lfs_fcat>-no_out  = 'X'.
            subtract 1 from lv_colpos.

          when 'TEXT_TO'.
            <lfs_fcat>-col_pos = lv_colpos.
            <lfs_fcat>-edit    = 'X'.
            <lfs_fcat>-seltext = lv_to.
            <lfs_fcat>-coltext = lv_to.

        endcase.

      endloop.

  endcase.

endform.

form alv_build using  value(v_gui_titlebar)  type gui_title
                      value(v_gui_title)     type lvc_title
                      value(v_cont_name)     type char10

                changing c_container         type ref to cl_gui_custom_container
                         c_alv               type ref to cl_gui_alv_grid
                         c_layout            type lvc_s_layo.

  set titlebar  v_gui_titlebar.

  c_layout-grid_title = v_gui_title.

  try.

    perform alv_destroy changing c_alv c_container.

    perform alv_create using v_cont_name changing c_container c_alv.

  endtry.

endform.

form alv_create using value(v_cont_name)     type char10

                      changing c_container   type ref to cl_gui_custom_container
                               c_alv         type ref to cl_gui_alv_grid.
  create object c_container
    exporting
      container_name     = v_cont_name.

  create object  c_alv
    exporting
      i_parent  = c_container->screen0.

  c_alv->set_graphics_container( exporting
                                   i_graphics_container = c_container ).

endform.

form alv_destroy changing c_alv       type ref to cl_gui_alv_grid
                          c_container type ref to cl_gui_custom_container.

  if not c_alv is initial.

    c_alv->free( exceptions
                   cntl_error              = 1
                   cntl_system_error       = 2
                   others                  = 3 ).

    if sy-subrc ne 0.
      free c_alv.
    endif.

  endif.

  if not c_container is initial.

    c_container->free( exceptions
                         cntl_error        = 1
                         cntl_system_error = 2
                         others            = 3 ).

    if sy-subrc ne 0.
      free c_container.
    endif.

  endif.

endform.

form build_new using value(v_mix) type zmsgtrans_t

               changing ct_from   type gwa_t100_t
                        ct_to     type gwa_t100_t.
  data: ls_mix  type zmsgtrans_s,
        ls_from type t100,
        ls_to   type t100.

  loop at v_mix into ls_mix.

    ls_from-sprsl = ls_mix-sprsl_from.
    ls_from-arbgb = ls_mix-arbgb.
    ls_from-msgnr = ls_mix-msgnr.
    ls_from-text  = ls_mix-text_from.

    append ls_from to ct_from.

    ls_to-sprsl   = ls_mix-sprsl_to.
    ls_to-arbgb   = ls_mix-arbgb.
    ls_to-msgnr   = ls_mix-msgnr.
    ls_to-text    = ls_mix-text_to.

    append ls_to to ct_to.

    clear: ls_from, ls_to, ls_mix.
  endloop.

endform.

form get_message using value(v_class) type arbgb
                       value(v_langu) type spras
                       value(v_msgnr) type tt_so_msgnr

                 changing ct_message  type gwa_t100_t.

  select *
  from t100
  into table ct_message
  where sprsl eq v_langu and
        arbgb eq v_class and
        msgnr in v_msgnr.           "#EC CI_SGLSELECT

endform.

form build_mix using value(v_langu_from) type spras
                     value(v_langu_to)   type spras
                     value(v_msg_from)   type gwa_t100_t
                     value(v_msg_to)     type gwa_t100_t

               changing ct_mix       type zmsgtrans_t.

  data: ls_mix  type zmsgtrans_s,
        ls_from type t100,
        ls_to   type t100.

  loop at v_msg_from into ls_from.

    ls_mix-arbgb      = ls_from-arbgb.
    ls_mix-msgnr      = ls_from-msgnr.
    ls_mix-sprsl_from = v_langu_from.
    ls_mix-text_from  = ls_from-text.
    ls_mix-sprsl_to   = v_langu_to.

    read table v_msg_to into ls_to with key sprsl = v_langu_to arbgb = ls_from-arbgb msgnr = ls_from-msgnr.

    if sy-subrc eq 0.
      ls_mix-text_to = ls_to-text.
    endif.

    append ls_mix to ct_mix.

    clear: ls_from, ls_to, ls_mix.
  endloop.

endform.
