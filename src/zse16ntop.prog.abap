*&---------------------------------------------------------------------*
*& Include ZSE16NTOP                                         Report ZSE16N
*&
*&---------------------------------------------------------------------*
REPORT ZSE16N.

##NEEDED
constants: gc_line type i value 105,
           gc_9000 type sydynnr value 9000,
           gc_9001 type sydynnr value 9001.

##NEEDED
types: begin of ts_so_msgnr,
         sign   type tvarv_sign,
         option type tvarv_opti,
         low    type msgnr,
         high   type msgnr,
       end of ts_so_msgnr,

       tt_so_msgnr type standard table of ts_so_msgnr.

##NEEDED
data: go_data       type ref to data,
      gt_query      type standard table of text255,
      gt_mix        type zmsgtrans_t,
      gt_sort       type lvc_t_sort,
      gt_fcat_9001  type lvc_t_fcat,
      gt_exclude    type ui_functions.

##NEEDED
data: gs_layout     type lvc_s_layo,
      gs_exclude    type ui_func.

##NEEDED
data: gv_title_9001 type lvc_title,
      gv_subrc      type sysubrc,
      gv_tmp        type text255,
      gv_query      type string,
      gv_tabname    type tabname.

##NEEDED
data: go_container  type ref to cl_gui_custom_container,
      go_area       type ref to cl_gui_custom_container,
      go_alv        type ref to cl_gui_alv_grid,
      go_editor     type ref to cl_gui_textedit.

##NEEDED
data: gs_message    type t100.

##NEEDED
field-symbols: <gt_data> type standard table.
