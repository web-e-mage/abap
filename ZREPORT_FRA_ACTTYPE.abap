**&---------------------------------------------------------------------*
**& Report ZREPORT_FRA_ACTIVITY
**&---------------------------------------------------------------------*
**&
**&---------------------------------------------------------------------*
REPORT zreport_fra_acttype_mig.

INCLUDE: zacttype_fra_data,
         zacttype_fra_sel,
         zacttype_fra_form.

INITIALIZATION.
  PERFORM f_init.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_l_path.
  PERFORM f_local_path USING p_l_path.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_log.
  PERFORM f_local_path USING p_log.

START-OF-SELECTION.
  PERFORM f_upload_local.
  PERFORM f_check_exist.
  PERFORM f_download_logs.
