*&---------------------------------------------------------------------*
*&  Include           ZSRM_USER_UPDATE_SU01D_TOP
*&---------------------------------------------------------------------*

INTERFACE if_global_types.
  TYPES: BEGIN OF type_final_output,
             bname      TYPE user_addr-bname,
             partner    TYPE but000-partner,
             old_name_first TYPE but000-name_first,
             new_name_first TYPE but000-name_first,
             old_name_last  TYPE but000-name_first,
             new_name_last  TYPE but000-name_first,
             old_email      TYPE adr6-smtp_addr,
             new_email      TYPE adr6-smtp_addr,
           END OF type_final_output.
  TYPES: type_final_output_tt TYPE STANDARD TABLE OF type_final_output
                              WITH NON-UNIQUE KEY bname.
ENDINTERFACE.                    "if_global_Type

*----------------------------------------------------------------------*
*       CLASS cl_report DEFINITION
*----------------------------------------------------------------------*
*  This class is responsible for fetching, formatting and presenting,
*  the data
*----------------------------------------------------------------------*
CLASS cl_report DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS: begin,
             get_final_data RETURNING value(rt_final_data)
                                      TYPE if_global_types=>type_final_output_tt.
  PRIVATE SECTION.
    TYPES: BEGIN OF type_but000,
               partner    TYPE but000-partner,
               name_last  TYPE but000-name_last,  "48
               name_first TYPE but000-name_first, "49
               persnumber TYPE but000-persnumber,
             END OF type_but000,

             BEGIN OF type_but020,
               partner    TYPE but020-partner,
               addrnumber TYPE but020-addrnumber,
             END OF type_but020,

             BEGIN OF type_user_ids,
               bname   TYPE usr21-bname,
               partner TYPE but000-partner,
             END OF type_user_ids,

             BEGIN OF type_user_addr,
               bname      TYPE user_addr-bname,
               name_first TYPE user_addr-name_first,
               name_last  TYPE user_addr-name_last,
             END OF type_user_addr,

             BEGIN OF type_usr21,
               bname      TYPE usr21-bname,
               persnumber TYPE usr21-persnumber,
               addrnumber TYPE usr21-addrnumber,
             END OF type_usr21,

             BEGIN OF type_adr6,
               addrnumber TYPE adr6-addrnumber,
               persnumber TYPE adr6-persnumber,
               smtp_addr  TYPE adr6-smtp_addr,
             END OF type_adr6,
             BEGIN OF type_update_table,
               bname      TYPE usr21-bname,
               name_first TYPE user_addr-name_first,
               name_last  TYPE user_addr-name_last,
               smtp_addr  TYPE adr6-smtp_addr,
             END OF type_update_table.

    DATA: t_but000       TYPE STANDARD TABLE OF type_but000,
          t_but020       TYPE STANDARD TABLE OF type_but020,
          t_user_ids     TYPE STANDARD TABLE OF type_user_ids,
          t_user_addr    TYPE STANDARD TABLE OF type_user_addr,
          t_usr21        TYPE STANDARD TABLE OF type_usr21,
          t_adr6         TYPE STANDARD TABLE OF type_adr6,
          t_update_table TYPE STANDARD TABLE OF type_update_table,
          t_final_output TYPE if_global_types=>type_final_output_tt.

    METHODS: get_data,
             get_user_id,
             compare,
             update.
ENDCLASS.                    "cl_report DEFINITION

*----------------------------------------------------------------------*
*       CLASS cl_email DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS cl_email DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS: constructor
               IMPORTING it_final_data TYPE if_global_types=>type_final_output_tt,
             begin.

  PRIVATE SECTION.
    DATA: t_final_data     TYPE if_global_types=>type_final_output_tt,
          t_binary_content TYPE solix_tab,
          t_mail_body      TYPE soli_tab.
    DATA: v_attachment TYPE string,
          v_size       TYPE so_obj_len.
    DATA: o_send_request TYPE REF TO cl_bcs,
          o_document     TYPE REF TO cl_document_bcs,
          o_sender       TYPE REF TO cl_sapuser_bcs,
          o_recipent     TYPE REF TO if_recipient_bcs.
    CONSTANTS: c_tab TYPE c VALUE cl_bcs_convert=>gc_tab,
               c_cr  TYPE c VALUE cl_bcs_convert=>gc_crlf.
    METHODS: prepare_attachment,
             prepare_email_body,
             prepare_bcs_structures,
             send_email.
ENDCLASS.                    "cl_email DEFINITION


*----------------------------------------------------------------------*
*       CLASS cl_main DEFINITION
*----------------------------------------------------------------------*
*  This is a singleton class which will act as the driver class. This
*  will orchestrate the program
*----------------------------------------------------------------------*
CLASS cl_main DEFINITION
               FINAL
               CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-DATA: o_driver TYPE REF TO cl_main READ-ONLY.
    CLASS-METHODS: instantiate RETURNING value(rv_instance) TYPE REF TO cl_main.
    METHODS: main_method,
             check_authority.
  PRIVATE SECTION.
    DATA: o_report TYPE REF TO cl_report,
          o_email  TYPE REF TO cl_email.
ENDCLASS.                    "cl_main DEFINITION

DATA: o_main TYPE REF TO cl_main.

DATA: v_bp            TYPE bu_partner,
      v_last_run_date TYPE zwday_last_run-last_run_date.
