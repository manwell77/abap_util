*&---------------------------------------------------------------------*
*&  Include           ZSE16NF01
*&---------------------------------------------------------------------*
form get_and_convert_fcat using  value(v_structure) type tabname
                                 value(vo_data)     type ref to data

                          changing  c_fcat          type lvc_t_fcat
                                    c_subrc         type sysubrc.

  data: lt_fcat_from type slis_t_fieldcat_alv.

  field-symbols: <lt_data> type standard table,
                 <ls_cat>  type lvc_s_fcat.

  clear c_subrc.

  call function 'REUSE_ALV_FIELDCATALOG_MERGE'
    exporting
      i_structure_name       = v_structure
    changing
      ct_fieldcat            = lt_fcat_from
    exceptions
      inconsistent_interface = 1
      program_error          = 2
      others                 = 3.

  if sy-subrc ne 0.
    add sy-subrc to c_subrc.
    return.
  endif.

  assign vo_data->* to <lt_data>.

  call function 'LVC_TRANSFER_FROM_SLIS'
    exporting
      it_fieldcat_alv = lt_fcat_from
    importing
      et_fieldcat_lvc = c_fcat
    tables
      it_data         = <lt_data>
    exceptions
      it_data_missing = 1
      others          = 2.

  if sy-subrc ne 0.
    add sy-subrc to c_subrc.
    return.
  endif.

  loop at c_fcat assigning <ls_cat>.
    if <ls_cat>-key ne 'X'. <ls_cat>-edit = 'X'. endif.
    clear: <ls_cat>-ref_table, <ls_cat>-ref_field.
  endloop.

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
      container_name = v_cont_name.

  create object c_alv
    exporting
      i_parent = c_container->screen0.

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

form get_data using value(vv_table) type tabname value(vv_query) type string changing co_table  type ref to data cv_subrc type sysubrc.

  field-symbols: <lt_data> type standard table.

  try.
      create data co_table type standard table of (vv_table).
      assign co_table->* to <lt_data>.
      if not vv_query is initial.
        select * from (vv_table) into table <lt_data> where (vv_query).
      else.
        select * from (vv_table) into table <lt_data>.
      endif.
    catch cx_static_check cx_dynamic_check.
      cv_subrc = 4.
  endtry.

endform.
