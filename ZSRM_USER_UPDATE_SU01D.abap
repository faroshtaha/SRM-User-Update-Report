*&---------------------------------------------------------------------*
*& Report  ZSRM_USER_UPDATE_SU01D
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT ZSRM_USER_UPDATE_SU01D.

INCLUDE ZSRM_USER_UPDATE_SU01D_TOP.
INCLUDE ZSRM_USER_UPDATE_SU01D_SEL.
INCLUDE ZSRM_USER_UPDATE_SU01D_F01.

INITIALIZATION.
  SELECT SINGLE last_run_date
    FROM zwday_last_run
      INTO v_last_run_date.

AT SELECTION-SCREEN OUTPUT.
  IF p_run IS INITIAL AND v_last_run_date IS NOT INITIAL.
    p_run = v_last_run_date.
  ENDIF.

START-OF-SELECTION.
*--------------------------------------------------------------------*
*  Instantiate Singleton class
*--------------------------------------------------------------------*
*  o_main = cl_main=>instantiate( ).
*--------------------------------------------------------------------*
*  Main Method
*--------------------------------------------------------------------*
*  o_main->main_method( ).
