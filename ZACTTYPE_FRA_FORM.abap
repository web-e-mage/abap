*&---------------------------------------------------------------------*
*& Include          ZACTTYPE_FRA_FORM
*&---------------------------------------------------------------------*
FORM f_init.

  FREE: gt_act,
        gt_crea,
        gt_mod,
        gt_logs,
        gt_heading.

  CLEAR: gv_flag.

ENDFORM.

FORM f_local_path USING pv_path.

  DATA: lt_filebin  TYPE filetable,
        ls_filestr  TYPE file_table,
        lv_rc       TYPE i,
        lv_fullpath TYPE filename.

  FREE: lt_filebin.

  CLEAR: ls_filestr,
         lv_rc,
         lv_fullpath.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    CHANGING
      file_table = lt_filebin
      rc         = lv_rc.
  IF sy-subrc EQ 0.
    READ TABLE lt_filebin INTO ls_filestr INDEX 1.
    lv_fullpath = ls_filestr-filename.
  ENDIF.

  pv_path = lv_fullpath.

ENDFORM.

FORM f_upload_local.

  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = p_l_path
      filetype                = 'ASC'
      has_field_separator     = abap_true
      codepage                = '4110'
    TABLES
      data_tab                = gt_act
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
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.

FORM f_check_exist.

  DATA: lt_check TYPE STANDARD TABLE OF ts_check,
        lv_tabix TYPE sy-tabix.

  FREE: lt_check.
  CLEAR: lv_tabix.

  SORT gt_act BY kokrs lstar spras.

  SELECT spras
         kokrs
         lstar
         datbi
  FROM cslt
  INTO TABLE lt_check
  FOR ALL ENTRIES IN gt_act
  WHERE kokrs EQ gt_act-kokrs
  AND lstar EQ gt_act-lstar.
  IF sy-subrc EQ 0.

    SORT lt_check BY kokrs lstar.
    DELETE ADJACENT DUPLICATES FROM lt_check
    COMPARING kokrs lstar.

    LOOP AT lt_check ASSIGNING FIELD-SYMBOL(<fs_check>).

      READ TABLE gt_act
      TRANSPORTING NO FIELDS
      WITH KEY kokrs = <fs_check>-kokrs
               lstar = <fs_check>-lstar
      BINARY SEARCH.
      IF sy-subrc EQ 0.
        lv_tabix = sy-tabix.
        LOOP AT gt_act ASSIGNING FIELD-SYMBOL(<fs_act>) FROM lv_tabix.

          IF <fs_check>-kokrs NE <fs_act>-kokrs
          OR <fs_check>-lstar NE <fs_act>-lstar.
            EXIT.
          ENDIF.

          APPEND <fs_act> TO gt_mod.
          DELETE gt_act INDEX lv_tabix.

        ENDLOOP.
      ENDIF.
    ENDLOOP.

    SORT gt_act BY kokrs lstar spras.

    LOOP AT gt_act ASSIGNING <fs_act>.

      READ TABLE gt_crea
      TRANSPORTING NO FIELDS
      WITH KEY lstar = <fs_act>-lstar
      BINARY SEARCH.
      IF sy-subrc EQ 0.
        APPEND <fs_act> TO gt_mod.
      ELSE.
        APPEND <fs_act> TO gt_crea.
      ENDIF.

    ENDLOOP.

  ELSE.

    LOOP AT gt_act ASSIGNING FIELD-SYMBOL(<fs_act_1>).

      READ TABLE gt_crea
      TRANSPORTING NO FIELDS
      WITH KEY lstar = <fs_act_1>-lstar
      BINARY SEARCH.
      IF sy-subrc EQ 0.
        APPEND <fs_act_1> TO gt_mod.
      ELSE.
        APPEND <fs_act_1> TO gt_crea.
      ENDIF.

    ENDLOOP.

  ENDIF.

  FREE gt_act.

  SORT gt_crea BY kokrs spras lstar.
  SORT gt_mod BY kokrs spras lstar.

  IF gt_crea IS NOT INITIAL.
    gv_flag = c_flag_crea.
    PERFORM f_bapi_table USING gt_crea.
  ENDIF.

  IF gt_mod IS NOT INITIAL.
    gv_flag = c_flag_mod.
    PERFORM f_bapi_table USING gt_mod.
  ENDIF.

ENDFORM.

FORM f_bapi_table USING pt_itab TYPE STANDARD TABLE.

  DATA: ls_lang     TYPE bapi0015_10,
        lt_act      TYPE STANDARD TABLE OF bapi1031_atinputlist,
        ls_act      TYPE bapi1031_atinputlist,
        lv_coarea   TYPE bapi1031_gen-co_area,
        lt_itab     TYPE STANDARD TABLE OF ts_act,
        lt_itab_tmp TYPE STANDARD TABLE OF ts_act,
        lv_tabix    TYPE sy-tabix.

  FREE: lt_act,
        lt_itab,
        lt_itab_tmp.

  CLEAR: ls_lang,
         ls_act,
         lv_coarea,
         lv_tabix.

  lt_itab_tmp = pt_itab[].
  SORT lt_itab_tmp BY kokrs spras.
  DELETE ADJACENT DUPLICATES FROM lt_itab_tmp
  COMPARING kokrs spras.

  lt_itab = pt_itab[].

  LOOP AT lt_itab_tmp ASSIGNING FIELD-SYMBOL(<fs_tmp>).

    ls_lang-langu = <fs_tmp>-spras.
    lv_coarea = <fs_tmp>-kokrs.

    READ TABLE lt_itab
    TRANSPORTING NO FIELDS
    WITH KEY kokrs = <fs_tmp>-kokrs
             spras = <fs_tmp>-spras
    BINARY SEARCH.
    IF sy-subrc EQ 0.
      lv_tabix = sy-tabix.
      LOOP AT lt_itab ASSIGNING FIELD-SYMBOL(<fs_act>) FROM lv_tabix.
        IF <fs_act>-kokrs NE <fs_tmp>-kokrs
        OR <fs_act>-spras NE <fs_tmp>-spras.
          EXIT.
        ENDIF.
        lv_coarea = <fs_act>-kokrs.
        ls_lang-langu = <fs_act>-spras.
        ls_act-acttype = <fs_act>-lstar.
        ls_act-valid_from = <fs_act>-datab.
        ls_act-valid_to = <fs_act>-datbi.
        ls_act-act_unit = <fs_act>-leinh.
        ls_act-act_unit_iso = <fs_act>-meinh1.
        ls_act-costcenter_cat = <fs_act>-kstty.
        ls_act-activity_cat = <fs_act>-latyp.
        ls_act-alloc_cost_elem = <fs_act>-vksta.
        ls_act-price_indicator = <fs_act>-tarkz.
        ls_act-average_price_ind = <fs_act>-yrate.
        ls_act-predis_fxd_cost = <fs_act>-fixvo.
        ls_act-manual_act_qty = <fs_act>-manist.
        ls_act-act_cat_actual = <fs_act>-latypi.
        ls_act-act_price_ind = <fs_act>-tarkz_i.
        ls_act-lock_indicator = <fs_act>-sprkz.
        ls_act-output_unit = <fs_act>-auseh.
        ls_act-output_unit_iso = <fs_act>-meinh2.
        ls_act-output_factor = <fs_act>-ausfk.
        ls_act-name = <fs_act>-ktext.
        ls_act-descript = <fs_act>-ltext.
        ls_act-manual_plan_qty = <fs_act>-manplan.

        APPEND ls_act TO lt_act.
        CLEAR ls_act.

      ENDLOOP.
    ENDIF.

    PERFORM f_bapi USING lv_coarea
                         ls_lang
                         lt_act.

    CLEAR: lv_coarea,
           ls_lang.

    FREE: lt_act.

  ENDLOOP.

ENDFORM.

FORM f_bapi USING pv_coarea TYPE bapi1031_gen-co_area
                  ps_lang TYPE bapi0015_10
                  pt_act TYPE STANDARD TABLE.

  DATA: lt_return       TYPE STANDARD TABLE OF bapiret2,
        ls_commit_ret   TYPE bapiret2,
        lt_precommit    TYPE STANDARD TABLE OF bapiret2,
        lv_subrc_e      TYPE sy-subrc,
        lv_subrc_x      TYPE sy-subrc,
        lv_subrc_a      TYPE sy-subrc,
        ls_rollback_ret TYPE bapiret2.

  FREE: lt_return,
        lt_precommit.

  CLEAR: ls_commit_ret,
         lv_subrc_e,
         lv_subrc_x,
         lv_subrc_a,
         ls_rollback_ret.

  CALL FUNCTION 'BAPI_PS_INITIALIZATION'.

  IF gv_flag EQ c_flag_crea.

    CALL FUNCTION 'BAPI_ACTTYPE_CREATEMULTIPLE'
      EXPORTING
        coarea           = pv_coarea
        language         = ps_lang
      TABLES
        activitytypelist = pt_act
        return           = lt_return.

  ELSEIF gv_flag EQ c_flag_mod.

    CALL FUNCTION 'BAPI_ACTTYPE_CHANGEMULTIPLE'
      EXPORTING
        coarea           = pv_coarea
        language         = ps_lang
      TABLES
        activitytypelist = pt_act
        return           = lt_return.

  ENDIF.

  READ TABLE lt_return
  TRANSPORTING NO FIELDS
  WITH KEY type = c_msg_e
  BINARY SEARCH.
  lv_subrc_e = sy-subrc.
  READ TABLE lt_return
  TRANSPORTING NO FIELDS
  WITH KEY type = c_msg_x
  BINARY SEARCH.
  lv_subrc_x = sy-subrc.
  READ TABLE lt_return
  TRANSPORTING NO FIELDS
  WITH KEY type = c_msg_a
  BINARY SEARCH.
  lv_subrc_a = sy-subrc.
  IF lv_subrc_e EQ 0
  OR lv_subrc_x EQ 0
  OR lv_subrc_a EQ 0.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
      IMPORTING
        return = ls_rollback_ret.
  ELSE.
    CLEAR: lv_subrc_e,
           lv_subrc_x,
           lv_subrc_a.

    CALL FUNCTION 'BAPI_PS_PRECOMMIT'
      TABLES
        et_return = lt_precommit.

    READ TABLE lt_precommit
    TRANSPORTING NO FIELDS
    WITH KEY type = c_msg_e
    BINARY SEARCH.
    lv_subrc_e = sy-subrc.
    READ TABLE lt_precommit
    TRANSPORTING NO FIELDS
    WITH KEY type = c_msg_x
    BINARY SEARCH.
    lv_subrc_x = sy-subrc.
    READ TABLE lt_precommit
    TRANSPORTING NO FIELDS
    WITH KEY type = c_msg_a
    BINARY SEARCH.
    lv_subrc_a = sy-subrc.
    IF lv_subrc_e EQ 0
    OR lv_subrc_x EQ 0
    OR lv_subrc_a EQ 0.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
        IMPORTING
          return = ls_rollback_ret.
    ELSE.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait   = abap_true
        IMPORTING
          return = ls_commit_ret.

    ENDIF.
  ENDIF.

  APPEND LINES OF lt_return TO gt_logs.
  APPEND LINES OF lt_precommit TO gt_logs.

  CLEAR: ls_commit_ret,
         ls_rollback_ret.

  FREE: lt_return,
        lt_precommit.

ENDFORM.

FORM f_download_logs.

  PERFORM f_heading.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      filename                = p_log
      filetype                = 'ASC'
      write_field_separator   = abap_true
    TABLES
      data_tab                = gt_logs
      fieldnames              = gt_heading
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
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      file_not_found          = 19
      dataprovider_exception  = 20
      control_flush_error     = 21
      OTHERS                  = 22.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  MESSAGE TEXT-002 TYPE c_msg_i.

ENDFORM.

FORM f_heading.

  DATA ls_heading TYPE ts_heading.

  ls_heading-text = TEXT-003. "type
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-004. "id
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-005. "number
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-006. "message
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-007. "log number
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-008. "log message number
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-009. "message v1
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-010. "message v2
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-011. "message v3
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-012. "message v4
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-013. "parameter
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-014. "row
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-015. "field
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-016. "system
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

ENDFORM.
