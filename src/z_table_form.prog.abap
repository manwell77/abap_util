*&---------------------------------------------------------------------*
*&  Include           Z_TABLE_FORM
*&---------------------------------------------------------------------*
FORM save_file_dialog .

  DATA : file_name TYPE string,
         l_path TYPE string,
         l_win_title TYPE string,
         l_fullpath TYPE string.

  MOVE text-m03 TO l_win_title.

  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      window_title         = l_win_title
      default_extension    = 'XLS'
      ##NO_TEXT
      default_file_name    = 'dtbtable'
      prompt_on_overwrite  = ' '
    CHANGING
      filename             = file_name
      path                 = l_path
      fullpath             = l_fullpath
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.
  IF sy-subrc = 0.
    MOVE l_fullpath TO i_file_path_d .
  ENDIF.

ENDFORM.                    "save_file_dialog

*&---------------------------------------------------------------------*
*&      Form  download_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download_table .

  TYPES: BEGIN OF st_header ,
           name(80),
         END OF st_header,
         tt_header TYPE STANDARD TABLE OF st_header.

  constants: gc_11 type i value 11,
             gc_12 type i value 12,
             gc_13 type i value 13,
             gc_14 type i value 14,
             gc_15 type i value 15,
             gc_16 type i value 16,
             gc_17 type i value 17,
             gc_18 type i value 18,
             gc_19 type i value 19,
             gc_20 type i value 20,
             gc_21 type i value 21,
             gc_22 type i value 22.

  DATA:  lo_struct          TYPE REF TO cl_abap_structdescr,
         lt_comp            TYPE cl_abap_structdescr=>component_table,
         lt_comp_descr      TYPE ddfields,
         la_comp_descr      TYPE dfies,
         la_comp            TYPE LINE OF cl_abap_structdescr=>component_table,
         lo_new_type        TYPE REF TO cl_abap_structdescr,
         lo_new_tab         TYPE REF TO cl_abap_tabledescr,
         lt_data            TYPE REF TO data,
         la_data            TYPE REF TO data,
         lt_header          TYPE tt_header,
         la_header          TYPE st_header,
         l_return           TYPE i,
         l_local_country    TYPE land1,
         lt_dd02l           TYPE STANDARD TABLE OF dd02l,
         lv_filetype        TYPE char10.


  FIELD-SYMBOLS: <f_line>   TYPE ANY,
                 <f_table>  TYPE STANDARD TABLE.


* Check mandatory data
  IF i_file_path_d IS INITIAL.
    MESSAGE text-e01 TYPE 'E'. return.
  ELSEIF i_table_struct_d IS INITIAL.
    MESSAGE text-e02 TYPE 'E'. return.
  ENDIF.

* Check table existence
  TRANSLATE i_table_struct_d TO UPPER CASE.
  SELECT * FROM dd02l INTO TABLE lt_dd02l WHERE tabname = i_table_struct_d.
  IF sy-subrc <> 0.
    MESSAGE text-e05 TYPE 'E'.
    return.
  ENDIF.

* Creiamo il tipo struttura e tabella
  lo_struct ?= cl_abap_structdescr=>describe_by_name( i_table_struct_d ).

* Get table fields
  PERFORM get_fields USING i_table_struct_d
                  CHANGING lt_comp
                           l_return.
  IF sy-subrc <> 0.
    MESSAGE text-e11 TYPE 'E'. return.
  ENDIF.

* Get field descr
  CALL METHOD lo_struct->get_ddic_field_list
    EXPORTING
      p_langu                  = sy-langu
      p_including_substructres = abap_false
    RECEIVING
      p_field_list             = lt_comp_descr
    EXCEPTIONS
      not_found                = 1
      no_ddic_type             = 2
      OTHERS                   = 3.
  IF sy-subrc <> 0.
    MESSAGE text-e00 TYPE 'E'. return.
  ENDIF.

* fieldname
  lv_filetype = 'ASC'.

  IF with_header_d IS NOT INITIAL.

    lv_filetype = 'DBF'.

    LOOP AT lt_comp INTO la_comp.

      ##WARN_OK
      READ TABLE lt_comp_descr WITH KEY fieldname = la_comp-name
        INTO la_comp_descr.

      IF sy-subrc <> 0.   MESSAGE text-e00 TYPE 'E'. EXIT. ENDIF.

      IF la_comp_descr-scrtext_l IS NOT INITIAL.
        MOVE la_comp_descr-scrtext_l TO la_header-name.
      ELSE.
        MOVE la_comp_descr-fieldname TO la_header-name.
      ENDIF.

      APPEND la_header TO lt_header.

      CLEAR: la_comp, la_header, la_comp_descr.
    ENDLOOP.
  ENDIF.

* Create STructure type
  lo_new_type = cl_abap_structdescr=>create( lt_comp ).

* Create tab type
  lo_new_tab = cl_abap_tabledescr=>create(
                  p_line_type  = lo_new_type
                  p_table_kind = cl_abap_tabledescr=>tablekind_std
                  p_unique     = abap_false ).

* Data to handle the new table type
  CREATE DATA lt_data TYPE HANDLE lo_new_tab.
  CREATE DATA la_data TYPE HANDLE lo_new_type.

* New internal table in the fieldsymbols
  ASSIGN lt_data->* TO <f_table>.
  ASSIGN la_data->* TO <f_line>.

* Get Table content
  SELECT *
   FROM (i_table_struct_d)
   INTO TABLE <f_table>.
  IF sy-subrc <> 0.
    MESSAGE text-e06 TYPE 'W'. return.
  ENDIF.

* set custom format on
  PERFORM set_custom_format_on USING custom_date_flag_d
                                     custom_decimal_flag_d
                                     custom_date_format_d
                                     custom_decimal_format_d
                            CHANGING l_local_country
                                     l_return.
  IF sy-subrc <> 0.
    MESSAGE text-e00 TYPE 'E'. return.
  ENDIF.

* Download table
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      filename                = i_file_path_d
      filetype                = lv_filetype
      write_field_separator   = 'X'
      confirm_overwrite       = 'X'
    TABLES
      data_tab                = <f_table>
      fieldnames              = lt_header
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = gc_11
      dp_error_send           = gc_12
      dp_error_write          = gc_13
      unknown_dp_error        = gc_14
      access_denied           = gc_15
      dp_out_of_memory        = gc_16
      disk_full               = gc_17
      dp_timeout              = gc_18
      file_not_found          = gc_19
      dataprovider_exception  = gc_20
      control_flush_error     = gc_21
      OTHERS                  = gc_22.
  IF sy-subrc <> 0.
    MESSAGE text-e03 TYPE 'E'.
  ENDIF.

  PERFORM set_custom_format_off USING l_local_country
                             CHANGING l_return.
  IF sy-subrc <> 0.
    MESSAGE text-e00 TYPE 'E'. return.
  ENDIF.

ENDFORM.                    " download_table
*&---------------------------------------------------------------------*
*&      Form  upload
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload .

  constants: gc_11 type i value 11,
             gc_12 type i value 12,
             gc_13 type i value 13,
             gc_14 type i value 14,
             gc_15 type i value 15,
             gc_16 type i value 16,
             gc_17 type i value 17,
             gc_18 type i value 18,
             gc_19 type i value 19.
  DATA:
    lo_struct           TYPE REF TO cl_abap_structdescr,
    lt_comp             TYPE cl_abap_structdescr=>component_table,
    lo_new_type         TYPE REF TO cl_abap_structdescr,
    lo_new_tab          TYPE REF TO cl_abap_tabledescr,
    lt_data             TYPE REF TO data,
    la_data             TYPE REF TO data,
    lv_fields           TYPE i,
    lt_input            TYPE TABLE OF string,
    la_riga             TYPE string,
    lt_riga             TYPE TABLE OF string,
    la_tmp_field        TYPE string,
    lv_separator        TYPE char1,
    la_return           TYPE bapiret1,
    lv_db_table         TYPE tabname16,
    lv_lines            TYPE i,
    lv_index            TYPE sytabix,
    la_decimal_format   TYPE st_decimal_format,
    la_date_format      TYPE st_date_format,
    l_return            TYPE i,
    lt_dd02l            TYPE STANDARD TABLE OF dd02l,
    lt_fields           TYPE cl_abap_structdescr=>component_table,
    la_fields           TYPE LINE OF cl_abap_structdescr=>component_table.

  FIELD-SYMBOLS:
    <f_line>            TYPE ANY ,
    <f_table>           TYPE STANDARD TABLE,
    <fs_data>           TYPE ANY.

* Check mandatory data
  IF i_file_path IS INITIAL.
    MESSAGE text-e01 TYPE 'E'.
  ELSEIF i_table_struct IS INITIAL.
    MESSAGE text-e02 TYPE 'E'.
  ENDIF.

* Check table existence
  TRANSLATE i_table_struct TO UPPER CASE.
  SELECT * FROM dd02l INTO TABLE lt_dd02l WHERE tabname = i_table_struct.
  IF sy-subrc <> 0.
    MESSAGE text-e05 TYPE 'E'.
    return.
  ENDIF.

* upload file
  CALL METHOD cl_gui_frontend_services=>gui_upload
    EXPORTING
      filename                = i_file_path
      filetype                = 'ASC'
    CHANGING
      data_tab                = lt_input
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = gc_11
      unknown_dp_error        = gc_12
      access_denied           = gc_13
      dp_out_of_memory        = gc_14
      disk_full               = gc_15
      dp_timeout              = gc_16
      not_supported_by_gui    = gc_17
      error_no_gui            = gc_18
      OTHERS                  = gc_19.
  IF sy-subrc <> 0.
    CLEAR la_return.
    la_return-type = 'E'.
    CASE sy-subrc.
      WHEN '1'.
        la_return-message = text-g01.
      WHEN '2'.
        la_return-message = text-g02.
      WHEN '3'.
        la_return-message = text-g03.
      WHEN '4'.
        la_return-message = text-g04.
      WHEN '5'.
        la_return-message = text-g05.
      WHEN '6'.
        la_return-message = text-g06.
      WHEN '7'.
        la_return-message = text-g07.
      WHEN '8'.
        la_return-message = text-g08.
      WHEN '9'.
        la_return-message = text-g09.
      WHEN '10'.
        la_return-message = text-g10.
      WHEN '11'.
        la_return-message = text-g11.
      WHEN '12'.
        la_return-message = text-g12.
      WHEN '13'.
        la_return-message = text-g13.
      WHEN '14'.
        la_return-message = text-g14.
      WHEN '15'.
        la_return-message = text-g15.
      WHEN '16'.
        la_return-message = text-g16.
      WHEN OTHERS.
        la_return-message = text-g17.
    ENDCASE.
    MESSAGE la_return-message TYPE la_return-type.
  ENDIF.

* column separator
  IF tab_separator EQ 'X'.
    lv_separator = cl_abap_char_utilities=>horizontal_tab.
  ELSE.
    lv_separator = selected_separator.
  ENDIF.

* Check custom decimal format
  IF custom_decimal_flag IS NOT INITIAL.
    IF gt_decimal_format IS INITIAL.
      PERFORM init_decimal_format_f4_help CHANGING gt_decimal_format.
    ENDIF.
    READ TABLE gt_decimal_format WITH KEY text = custom_decimal_format
      INTO la_decimal_format.
    IF sy-subrc <> 0.
      MESSAGE text-e07 TYPE 'E'. return.
    ENDIF.
  ENDIF.

* Check custom date format
  IF custom_date_flag IS NOT INITIAL.
    IF gt_date_format IS INITIAL.
      PERFORM init_date_format_f4_help CHANGING gt_date_format.
    ENDIF.
    READ TABLE gt_date_format WITH KEY text = custom_date_format
      INTO la_date_format.
    IF sy-subrc <> 0.
      MESSAGE text-e08 TYPE 'E'. return.
    ENDIF.
  ENDIF.

* Creiamo il tipo struttura e tabella
  lo_struct ?= cl_abap_structdescr=>describe_by_name( i_table_struct ).
  IF sy-subrc <> 0. MESSAGE text-e00 TYPE 'E'. return. ENDIF.

* Comp
  lt_comp = lo_struct->get_components( ).
  IF sy-subrc <> 0. MESSAGE text-e00 TYPE 'E'. return. ENDIF.

* Create Structure type
  lo_new_type = cl_abap_structdescr=>create( lt_comp ).

* Create tab type
  lo_new_tab = cl_abap_tabledescr=>create(
                  p_line_type  = lo_new_type
                  p_table_kind = cl_abap_tabledescr=>tablekind_std
                  p_unique     = abap_false ).

* Data to handle the new table type
  CREATE DATA lt_data TYPE HANDLE lo_new_tab.
  CREATE DATA la_data TYPE HANDLE lo_new_type.

* New internal table in the fieldsymbols
  ASSIGN lt_data->* TO <f_table>.
  ASSIGN la_data->* TO <f_line>.

* Get table fields
  PERFORM get_fields USING i_table_struct
                  CHANGING lt_fields
                           l_return.
  IF l_return <> 0. MESSAGE text-e00 TYPE 'E'. return. ENDIF.
  DESCRIBE TABLE lt_fields LINES lv_fields.

* Handle file data
  LOOP AT lt_input INTO la_riga.

*   Store file line
    MOVE sy-tabix TO lv_index.

*   Skip Header Line
    IF with_header EQ 'X' AND sy-tabix EQ '1'.
      CONTINUE.
    ENDIF.

    PERFORM split USING la_riga
                        lv_separator
               CHANGING lt_riga.

    DESCRIBE TABLE lt_riga LINES lv_lines.
    IF lv_lines NE lv_fields.

      la_return-type = 'E'.
      MOVE lv_index TO la_return-message.
      CONCATENATE text-g20 la_return-message INTO la_return-message
        SEPARATED BY space.

      MESSAGE la_return-message TYPE la_return-type.
      EXIT.

    ENDIF.

    LOOP AT lt_riga INTO la_tmp_field.

*     Assign
      IF <fs_data> IS ASSIGNED. UNASSIGN <fs_data>. ENDIF.

      TRY.
          ASSIGN COMPONENT sy-tabix OF STRUCTURE <f_line> TO <fs_data>.
          IF sy-subrc <> 0.

            la_return-type = 'E'.

            MOVE lv_index TO la_return-message.

            CONCATENATE text-g21 la_return-message INTO la_return-message
              SEPARATED BY space.

            MESSAGE la_return-message TYPE la_return-type.
            EXIT.
          ENDIF.

        CATCH: cx_sy_assign_cast_illegal_cast
               cx_sy_assign_cast_unknown_type
               cx_sy_assign_out_of_range.

          la_return-type = 'E'.
          MOVE lv_index TO la_return-message.
          CONCATENATE text-g21 la_return-message INTO la_return-message
            SEPARATED BY space.
          MESSAGE la_return-message TYPE la_return-type.
          EXIT.

      ENDTRY.

*     Get Field Type kind
      READ TABLE lt_fields INDEX sy-tabix INTO la_fields.
      IF sy-subrc <> 0. MESSAGE text-e00 TYPE 'E'. return. ENDIF.


*     Date format option
      IF custom_date_flag IS NOT INITIAL AND
       ( la_fields-type->type_kind = cl_abap_typedescr=>typekind_date ).

        PERFORM conv_date_to_internal USING la_tmp_field
                                            la_date_format
                                   CHANGING la_tmp_field.

      ENDIF.

*     Number format option
      IF custom_decimal_flag IS NOT INITIAL AND
       ( ( la_fields-type->type_kind = cl_abap_typedescr=>typekind_num   )  OR
         ( la_fields-type->type_kind = cl_abap_typedescr=>typekind_float ) OR
         ( la_fields-type->type_kind = cl_abap_typedescr=>typekind_int   ) OR
         ( la_fields-type->type_kind = cl_abap_typedescr=>typekind_int1  ) OR
         ( la_fields-type->type_kind = cl_abap_typedescr=>typekind_int2  ) OR
         ( la_fields-type->decimals > 0 )  ).

        PERFORM conv_decimal_to_internal USING la_tmp_field
                                               la_decimal_format
                                      CHANGING la_tmp_field.

      ENDIF.

*     Move
      TRY.
          MOVE la_tmp_field TO <fs_data>.
        CATCH: cx_sy_conversion_no_number
               cx_sy_conversion_overflow
               cx_sy_move_cast_error.
          CLEAR la_return.
          la_return-type = 'E'.
          la_return-message = text-g18 .
          MESSAGE la_return-message TYPE la_return-type.
          EXIT.
      ENDTRY.

      CLEAR la_tmp_field.
    ENDLOOP.

    APPEND <f_line> TO <f_table>.

  ENDLOOP.

* DTB insert/modify
  MOVE i_table_struct TO lv_db_table.
  IF rb_modify IS NOT INITIAL.
    MODIFY (lv_db_table) FROM TABLE <f_table>.
    IF sy-subrc = 0.
      MESSAGE text-m02 TYPE 'S'.
    ELSE.
      MESSAGE text-e04 TYPE 'E'.
    ENDIF.
  ELSE.
    TRY.
        INSERT (lv_db_table) FROM TABLE <f_table>.
      CATCH cx_sy_open_sql_db.
        CLEAR la_return.
        la_return-type = 'E'.
        la_return-message = text-g19 .
        MESSAGE la_return-message TYPE la_return-type.
        return.
    ENDTRY.
    COMMIT WORK AND WAIT.
    MESSAGE text-m01 TYPE 'S'.
  ENDIF.


ENDFORM.                    " upload
*&---------------------------------------------------------------------*
*&      Form  split
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_WA_RIGA  text
*      -->P_SEPARATOR  text
*      <--P_T_RIGA  text
*----------------------------------------------------------------------*
FORM split  USING value(v_line)      TYPE string
                  value(v_separator) TYPE char1
            CHANGING ct_split        TYPE tt_string.


  TYPES:
    BEGIN OF st_sep,
      pos TYPE i,
    END OF st_sep,
    tt_sep TYPE STANDARD TABLE OF st_sep.

  DATA:
    wa_split         TYPE string,
    lt_sep_pos       TYPE tt_sep,
    wa_sep_pos       TYPE st_sep,
    wa_sep_pos_next  TYPE st_sep,
    l_shift          TYPE i,
    l_index          TYPE sytabix,
    l_lenght         TYPE i,
    l_len            TYPE i.

  REFRESH ct_split.

  l_len = STRLEN( v_line ).
  IF l_len <= 0. return. ENDIF.

  DO l_len TIMES.


    IF v_line+l_shift(1) EQ v_separator.
      wa_sep_pos-pos = l_shift + 1.
      APPEND wa_sep_pos TO lt_sep_pos.
    ENDIF.

    l_shift = l_shift + 1.

  ENDDO.

  IF lt_sep_pos IS INITIAL.
    MOVE v_line TO wa_split.
    APPEND wa_split TO ct_split.
    return.
  ENDIF.

  CLEAR: wa_split, wa_sep_pos, l_shift, l_lenght.
  READ TABLE lt_sep_pos INDEX 1 INTO wa_sep_pos.
  IF wa_sep_pos-pos > 1 .
    l_lenght = wa_sep_pos-pos - 1.
    MOVE v_line+l_shift(l_lenght) TO wa_split.
  ENDIF.
  APPEND wa_split TO ct_split.


  CLEAR: wa_split, wa_sep_pos, l_shift, l_lenght.
  LOOP AT lt_sep_pos INTO wa_sep_pos.

    l_shift = wa_sep_pos-pos .

    MOVE sy-tabix TO l_index.
    l_index = l_index + 1.
    READ TABLE lt_sep_pos INDEX l_index INTO wa_sep_pos_next.
    IF sy-subrc = 0.
      l_lenght = wa_sep_pos_next-pos - wa_sep_pos-pos - 1.
    ELSE.
      l_lenght = l_len - wa_sep_pos-pos .
    ENDIF.

    MOVE v_line+l_shift(l_lenght) TO wa_split.
    APPEND wa_split TO ct_split.

    CLEAR: wa_split, wa_sep_pos, l_shift, l_lenght, wa_sep_pos_next, l_index.
  ENDLOOP.

ENDFORM.                    " split
*&---------------------------------------------------------------------*
*&      Form  open_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM open_file CHANGING c_file_path TYPE string.

  DATA l_win_title TYPE string.
  DATA l_rtrncode TYPE i.
  DATA lt_filetable TYPE filetable.
  DATA la_filetable TYPE file_table.

  MOVE text-m04 TO l_win_title.


  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = l_win_title
    CHANGING
      file_table              = lt_filetable
      rc                      = l_rtrncode
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.

  IF sy-subrc <> 0.
    MESSAGE text-e00  TYPE 'E'.
  ENDIF.

  READ TABLE lt_filetable INDEX 1 INTO la_filetable.
  IF sy-subrc = 0.
    MOVE la_filetable-filename TO c_file_path.
  ENDIF.

ENDFORM.                    " open_file
*&---------------------------------------------------------------------*
*&      Form  custom_date_format_f4_help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM custom_date_format_f4_help .

  IF gt_date_format IS INITIAL.
    PERFORM init_date_format_f4_help CHANGING gt_date_format.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'TEXT' "campo della tabella
      dynpprog    = sy-cprog
      dynpnr      = sy-dynnr
      dynprofield = 'CUSTOM_DATE_FORMAT' "field della screen
      value_org   = 'S'
    TABLES
      value_tab   = gt_date_format.

ENDFORM.                    " custom_date_format_f4_help
*&---------------------------------------------------------------------*
*&      Form  custom_decimal_format_f4_help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM custom_decimal_format_f4_help .

  IF gt_decimal_format IS INITIAL.
    PERFORM init_decimal_format_f4_help CHANGING gt_decimal_format.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'TEXT' "campo della tabella
      dynpprog    = sy-cprog
      dynpnr      = sy-dynnr
      dynprofield = 'CUSTOM_DECIMAL_FORMAT' "field della screen
      value_org   = 'S'
    TABLES
      value_tab   = gt_decimal_format.


ENDFORM.                    " custom_decimal_format_f4_help
*&---------------------------------------------------------------------*
*&      Form  init_date_format_f4_help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_DATE_FORMAT  text
*----------------------------------------------------------------------*
FORM init_date_format_f4_help  CHANGING ct_date_format TYPE tt_date_format.

*1  DD.MM.YYYY
*2  MM/DD/YYYY
*3  MM-DD-YYYY
*4  YYYY.MM.DD
*5  YYYY/MM/DD
*6  YYYY-MM-DD

  DATA wa_date_format TYPE st_date_format.

  wa_date_format-datfm = 1.
  wa_date_format-text  = 'DD.MM.YYYY'.
  APPEND wa_date_format TO ct_date_format.

  wa_date_format-datfm = 2.
  wa_date_format-text  = 'MM/DD/YYYY'.
  APPEND wa_date_format TO ct_date_format.

  wa_date_format-datfm = 3.
  wa_date_format-text  = 'MM-DD-YYYY'.
  APPEND wa_date_format TO ct_date_format.

  wa_date_format-datfm = 4.
  wa_date_format-text  = 'YYYY.MM.DD'.
  APPEND wa_date_format TO ct_date_format.

  wa_date_format-datfm = 5.
  wa_date_format-text  = 'YYYY/MM/DD'.
  APPEND wa_date_format TO ct_date_format.

  wa_date_format-datfm = 6.
  wa_date_format-text  = 'YYYY-MM-DD'.
  APPEND wa_date_format TO ct_date_format.


ENDFORM.                    " init_date_format_f4_help
*&---------------------------------------------------------------------*
*&      Form  init_decimal_format_f4_help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_DECIMAL_FORMAT  text
*----------------------------------------------------------------------*
FORM init_decimal_format_f4_help  CHANGING ct_decimal_format TYPE tt_decimal_format.

*X  Decimal point is period: N,NNN.NN
*   Decimal point is comma: N.NNN,NN
*Y  Decimal point is N NNN NNN,NN

  DATA wa_decimal_format TYPE st_decimal_format.

  wa_decimal_format-decfm = 'X'.
  wa_decimal_format-text  = 'N,NNN,NNN.NN'.
  APPEND wa_decimal_format TO ct_decimal_format.

  wa_decimal_format-decfm = ' '.
  wa_decimal_format-text  = 'N.NNN.NNN,NN'.
  APPEND wa_decimal_format TO ct_decimal_format.

  wa_decimal_format-decfm = 'Y'.
  wa_decimal_format-text  = 'N NNN NNN,NN'.
  APPEND wa_decimal_format TO ct_decimal_format.

ENDFORM.                    " init_decimal_format_f4_help
*&---------------------------------------------------------------------*
*&      Form  handle_date_format
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LA_DATE_FORMAT  text
*      <--P_LA_TMP_FIELD  text
*----------------------------------------------------------------------*
FORM conv_date_to_internal USING value(v_input)        TYPE string
                                 value(va_date_format) TYPE st_date_format
                        CHANGING c_output              TYPE string.

* constants
  CONSTANTS lc_int_date_len TYPE i VALUE 8.

* nothing to do if input field is initial
  CHECK: NOT v_input IS INITIAL.

* distinguish between different date formats
  CASE va_date_format-datfm.

    WHEN '1'.	"DD.MM.YYYY
      REPLACE ALL OCCURRENCES OF '.' IN v_input WITH space.
      CONDENSE v_input NO-GAPS.
      IF STRLEN( v_input ) NE lc_int_date_len. MESSAGE text-e00 TYPE 'E'. return. ENDIF.
      CONCATENATE  v_input+4(4) "yyyy
                   v_input+2(2) "mm
                   v_input(2)   "dd
             INTO c_output.

    WHEN '2'.	"MM/DD/YYYY
      REPLACE ALL OCCURRENCES OF '/' IN v_input WITH space.
      CONDENSE v_input NO-GAPS.
      IF STRLEN( v_input ) NE lc_int_date_len. MESSAGE text-e00 TYPE 'E'. return. ENDIF.
      CONCATENATE  v_input+4(4) "yyyy
                   v_input(2)   "mm
                   v_input+2(2) "dd
             INTO c_output.

    WHEN '3'.	"MM-DD-YYYY
      REPLACE ALL OCCURRENCES OF '-' IN v_input WITH space.
      CONDENSE v_input NO-GAPS.
      IF STRLEN( v_input ) NE lc_int_date_len. MESSAGE text-e00 TYPE 'E'. return. ENDIF.
      CONCATENATE  v_input+4(4) "yyyy
                   v_input(2)   "mm
                   v_input+2(2) "dd
             INTO c_output.

    WHEN '4'.	"YYYY.MM.DD
      REPLACE ALL OCCURRENCES OF '.' IN v_input WITH space.
      CONDENSE v_input NO-GAPS.
      IF STRLEN( v_input ) NE lc_int_date_len. MESSAGE text-e00 TYPE 'E'. return. ENDIF.
      MOVE v_input TO c_output.

    WHEN '5'.	"YYYY/MM/DD
      REPLACE ALL OCCURRENCES OF '/' IN v_input WITH space.
      CONDENSE v_input NO-GAPS.
      IF STRLEN( v_input ) NE lc_int_date_len. MESSAGE text-e00 TYPE 'E'. return. ENDIF.
      MOVE v_input TO c_output.

    WHEN '6'.	"YYYY-MM-DD
      REPLACE ALL OCCURRENCES OF '-' IN v_input WITH space.
      CONDENSE v_input NO-GAPS.
      IF STRLEN( v_input ) NE lc_int_date_len. MESSAGE text-e00 TYPE 'E'. return. ENDIF.
      MOVE v_input TO c_output.

    WHEN OTHERS.
      MESSAGE text-e00 TYPE 'E'. return.

  ENDCASE.

ENDFORM.                    " handle_date_format
*&---------------------------------------------------------------------*
*&      Form  handle_decimal_format
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LA_DATE_FORMAT  text
*      <--P_LA_TMP_FIELD  text
*----------------------------------------------------------------------*
FORM conv_decimal_to_internal USING value(v_input)           TYPE string
                                    value(va_decimal_format) TYPE st_decimal_format
                           CHANGING c_output                 TYPE string.



  DATA: lv_len1 TYPE i, "total string length
        lv_len2 TYPE i. "total string length minus 1

* nothing to do if input field is initial
  CHECK: NOT v_input IS INITIAL.
  MOVE v_input TO c_output.

* distinguish between different decimal formats
  CASE va_decimal_format-decfm.

    WHEN space.   "format N.NNN,NN
      REPLACE ALL OCCURRENCES OF '.' IN c_output WITH space.
      REPLACE ALL OCCURRENCES OF ',' IN c_output WITH '.'.

    WHEN 'X'.   "format N,NNN.NN
      REPLACE ALL OCCURRENCES OF ',' IN c_output WITH space.

    WHEN 'Y'. "format N NNN NNN,NN
      CONDENSE c_output NO-GAPS.
      REPLACE ALL OCCURRENCES OF ',' IN c_output WITH '.'.

    WHEN OTHERS.
      MESSAGE text-e00 TYPE 'E'. return.

  ENDCASE.
  CONDENSE c_output NO-GAPS.

* if last character is a '-', then shift it to the first position
  lv_len1 = STRLEN( c_output ).
  lv_len2 = lv_len1 - 1.
  IF c_output+lv_len2(1) = '-'.
    CONCATENATE '-' c_output(lv_len2) INTO c_output.
    CONDENSE c_output NO-GAPS.
  ENDIF.

ENDFORM.                    " handle_decimal_format

*&---------------------------------------------------------------------*
*&      Form  get_component
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_TAB  text
*      <--P_LT_COMP  text
*      <--P_L_ERROR  text
*----------------------------------------------------------------------*
FORM get_fields USING value(v_tab_name) TYPE any
             CHANGING ct_fields         TYPE abap_component_tab
                      c_return          TYPE i.


  DATA: lt_comp  TYPE abap_component_tab.

  IF v_tab_name IS INITIAL. ADD 4 TO c_return. return. ENDIF.

  PERFORM get_struct_component USING v_tab_name
                            CHANGING lt_comp
                                     c_return.
  IF c_return <> 0. return. ENDIF.


  PERFORM get_components_fields USING lt_comp
                             CHANGING ct_fields
                                      c_return.
  IF c_return <> 0. return. ENDIF.


ENDFORM.                    " get_component
*&---------------------------------------------------------------------*
*&      Form  get_single_fields
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LA_COMP_TEMP  text
*      <--P_LT_COMP  text
*----------------------------------------------------------------------*
FORM get_component_fields USING value(va_comp) TYPE abap_componentdescr
                       CHANGING ct_fields      TYPE abap_component_tab
                                c_return       TYPE i.

  DATA: lt_comp_temp  TYPE abap_component_tab,
        l_struct_name TYPE abap_abstypename.

  IF     va_comp-type->kind = cl_abap_datadescr=>kind_elem.

    APPEND va_comp TO ct_fields.

  ELSEIF va_comp-type->kind = cl_abap_datadescr=>kind_struct.

    l_struct_name = va_comp-type->absolute_name.
    SHIFT l_struct_name BY 6 PLACES.

    PERFORM get_struct_component USING l_struct_name
                              CHANGING lt_comp_temp
                                       c_return.
    IF c_return <> 0. return. ENDIF.

    PERFORM get_components_fields USING lt_comp_temp
                               CHANGING ct_fields
                                        c_return.

    IF c_return <> 0. return. ENDIF.

  ELSE.

    ADD 4 TO c_return. return.

  ENDIF.

ENDFORM.                    " get_single_fields
*&---------------------------------------------------------------------*
*&      Form  get_struct_comp
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_V_TAB_NAME  text
*      <--P_LT_COMP_TEMP  text
*      <--P_C_RETURN  text
*----------------------------------------------------------------------*
FORM get_struct_component USING value(v_tab_name) TYPE any
                       CHANGING ct_comp           TYPE abap_component_tab
                                c_return          TYPE i.


  DATA: lo_struct TYPE REF TO cl_abap_structdescr.

  lo_struct ?= cl_abap_structdescr=>describe_by_name( p_name =  v_tab_name ).
  IF sy-subrc <> 0.  ADD 4 TO c_return. return. ENDIF.

  ct_comp = lo_struct->get_components( ).
  IF sy-subrc <> 0.  ADD 4 TO c_return. return. ENDIF.

ENDFORM.                    " get_struct_comp
*&---------------------------------------------------------------------*
*&      Form  get_components_fields
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_COMP  text
*      <--P_LT_FIELDS  text
*      <--P_C_RETURN  text
*----------------------------------------------------------------------*
FORM get_components_fields USING value(vt_comp) TYPE abap_component_tab
                           CHANGING ct_fields   TYPE abap_component_tab
                                    c_return    TYPE i.

  DATA la_comp TYPE abap_componentdescr.

  LOOP AT vt_comp INTO la_comp.

    PERFORM get_component_fields USING la_comp
                              CHANGING ct_fields
                                        c_return.

    IF c_return <> 0. return. ENDIF.

    CLEAR la_comp.
  ENDLOOP.

ENDFORM.                    " get_components_fields
*&---------------------------------------------------------------------*
*&      Form  custom_date_format_d_f4_help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM custom_date_format_d_f4_help .

  IF gt_date_format_d[] IS INITIAL.
    PERFORM init_date_format_f4_help CHANGING gt_date_format_d.
  ENDIF.

* set sh values
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'TEXT' "campo della tabella
      dynpprog    = sy-cprog
      dynpnr      = sy-dynnr
      dynprofield = 'CUSTOM_DATE_FORMAT_D' "field della screen
      value_org   = 'S'
    TABLES
      value_tab   = gt_date_format_d.

ENDFORM.                    " custom_date_format_d_f4_help
*&---------------------------------------------------------------------*
*&      Form  custom_dec_format_d_f4_help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM custom_dec_format_d_f4_help .

  IF gt_decimal_format_d IS INITIAL.
    PERFORM init_decimal_format_f4_help CHANGING gt_decimal_format_d.
  ENDIF.


* set sh values
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'TEXT' "campo della tabella
      dynpprog    = sy-cprog
      dynpnr      = sy-dynnr
      dynprofield = 'CUSTOM_DECIMAL_FORMAT_D' "field della screen
      value_org   = 'S'
    TABLES
      value_tab   = gt_decimal_format_d.

ENDFORM.                    " custom_dec_format_d_f4_help
*&---------------------------------------------------------------------*
*&      Form  set_custom_format_on
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CUSTOM_DATE_FLAG_D  text
*      -->P_CUSTOM_DECIMAL_FLAG_D  text
*      -->P_CUSTOM_DATE_FORMAT  text
*      -->P_CUSTOM_DECIMAL_FORMAT  text
*      -->P_CAHNGING  text
*      -->P_L_RETURN  text
*----------------------------------------------------------------------*
FORM set_custom_format_on USING value(v_custom_date_flag_d)      TYPE char1
                                value(v_custom_decimal_flag_d)   TYPE char1
                                value(v_custom_date_format_d)    TYPE char10
                                value(v_custom_decimal_format_d) TYPE char12
                       CHANGING c_local_country                  TYPE land1
                                c_return                         TYPE i.

  DATA: lt_country        TYPE STANDARD TABLE OF t005x,
        la_country        TYPE t005x,
        la_date_format    TYPE st_date_format,
        la_decimal_format TYPE st_decimal_format,
        ##NEEDED
        l_lang            TYPE tcp0c-langu,
        ##NEEDED
        l_mod             TYPE tcp0c-modifier.

* Check input
  IF v_custom_date_flag_d    IS INITIAL AND
     v_custom_decimal_flag_d IS INITIAL.
    return.
  ENDIF.

* select countries
  SELECT * FROM t005x INTO TABLE lt_country.

* date
  IF v_custom_date_format_d IS NOT INITIAL.

    IF gt_date_format_d[] IS INITIAL.
      PERFORM init_date_format_f4_help CHANGING gt_date_format_d.
    ENDIF.

    READ TABLE gt_date_format_d
      WITH KEY text = v_custom_date_format_d
      INTO la_date_format.
    IF sy-subrc <> 0. ADD 4 TO c_return. return. ENDIF.

    LOOP AT lt_country INTO la_country WHERE datfm NE la_date_format-datfm.
      DELETE lt_country INDEX sy-tabix.
    ENDLOOP.

  ENDIF.

* decimal
  IF v_custom_decimal_flag_d IS NOT INITIAL.

    IF gt_decimal_format_d IS INITIAL.
      PERFORM init_decimal_format_f4_help CHANGING gt_decimal_format_d.
    ENDIF.

    READ TABLE gt_decimal_format_d
      WITH KEY text = v_custom_decimal_format_d
      INTO la_decimal_format.
    IF sy-subrc <> 0. ADD 4 TO c_return. return. ENDIF.

    LOOP AT lt_country INTO la_country WHERE xdezp NE la_decimal_format-decfm.
      DELETE lt_country INDEX sy-tabix.
    ENDLOOP.

  ENDIF.

* search country
  IF lt_country[] IS INITIAL. ADD 4 TO c_return. return. ENDIF.

  READ TABLE lt_country INDEX 1 INTO la_country.

  GET LOCALE LANGUAGE l_lang COUNTRY c_local_country  MODIFIER l_mod.
  IF sy-subrc <> 0. ADD 4 TO c_return. return. ENDIF.

  SET COUNTRY la_country-land.
  IF sy-subrc <> 0. ADD 4 TO c_return. return. ENDIF.


ENDFORM.                    " set_custom_format_on
*&---------------------------------------------------------------------*
*&      Form  set_custom_format_off
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_L_RETURN  text
*----------------------------------------------------------------------*
FORM set_custom_format_off USING value(v_local_country) TYPE land1
                        CHANGING c_return TYPE i.

  SET COUNTRY v_local_country.

  IF sy-subrc <> 0. ADD 4 TO c_return. return. ENDIF.

ENDFORM.                    " set_custom_format_off
