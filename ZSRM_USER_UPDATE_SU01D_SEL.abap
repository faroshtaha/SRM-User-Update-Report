*&---------------------------------------------------------------------*
*&  Include           ZSRM_USER_UPDATE_SU01D_SEL
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-b01.
SELECT-OPTIONS: so_bp  FOR v_bp.
PARAMETERS: p_run LIKE v_last_run_date.
SELECTION-SCREEN END OF BLOCK b1.
