*&---------------------------------------------------------------------*
*& Include ZMSGTRANSLATIONTOP                                Report ZMSGTRANSLATION
*&
*&---------------------------------------------------------------------*

report zmsgtranslation.

##NEEDED
types: begin of ts_so_msgnr,
         sign   type tvarv_sign,
         option type tvarv_opti,
         low    type msgnr,
         high   type msgnr,
       end of ts_so_msgnr,

       tt_so_msgnr type standard table of ts_so_msgnr.

##NEEDED
data: gt_from       type standard table of t100,
      gt_to         type standard table of t100,
      gt_mix        type zmsgtrans_t,
      gt_sort       type lvc_t_sort,
      gt_fcat_9001  type lvc_t_fcat,
      gt_exclude    type ui_functions.

##NEEDED
data: gs_layout     type lvc_s_layo,
      gs_exclude    type ui_func.

##NEEDED
data: gv_title_9001 type lvc_title,
      gv_subrc      type sysubrc.

##NEEDED
data: go_container  type ref to cl_gui_custom_container,
      go_alv        type ref to cl_gui_alv_grid.

##NEEDED
data: gs_message    type t100.
