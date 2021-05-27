*&---------------------------------------------------------------------*
*&  Include           ZSRM_USER_UPDATE_SU01D_F01
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
*       CLASS cl_main IMPLEMENTATION
*----------------------------------------------------------------------*
*  This is a singleton class which will act as the driver class. This
*  will orchestrate the program
*----------------------------------------------------------------------*
CLASS cl_main IMPLEMENTATION.
  METHOD instantiate.
    IF o_driver IS INITIAL.
      CREATE OBJECT o_driver.
    ENDIF.
    rv_instance = o_driver.
  ENDMETHOD.                    "instantiate

  METHOD main_method.
    CREATE OBJECT me->o_report.
    me->o_report->begin( ).

    CREATE OBJECT me->o_email
      EXPORTING
        it_final_data = me->o_report->get_final_data( ).

    me->o_email->begin( ).
  ENDMETHOD.                    "main_method

  METHOD check_authority.
  ENDMETHOD.                    "check_authority
ENDCLASS.                    "lcl_main IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS cl_report IMPLEMENTATION
*----------------------------------------------------------------------*
*  This class is responsible for fetching, formatting and presenting,
*  the data
*----------------------------------------------------------------------*
CLASS cl_report IMPLEMENTATION.
  METHOD begin.
    me->get_data( ).
    me->compare( ).
    me->update( ).
  ENDMETHOD.                    "begin

  METHOD get_data.
    TYPES: BEGIN OF ltype_but_addr_pers,
             addrnumber TYPE adr6-addrnumber,
             persnumber TYPE adr6-persnumber,
           END OF ltype_but_addr_pers.
    DATA: lt_addr_pers TYPE STANDARD TABLE OF ltype_but_addr_pers.

    DATA: lw_but000    TYPE me->type_but000,
          lw_but020    TYPE me->type_but020,
          lw_usr21     TYPE me->type_usr21,
          lw_addr_pers TYPE ltype_but_addr_pers.

*--------------------------------------------------------------------*
*    Begin of Business Partner data
*--------------------------------------------------------------------*
    SELECT  partner
            name_last  "48
            name_first "49
            persnumber "73
            FROM but000
            INTO TABLE me->t_but000
              WHERE partner IN so_bp
                AND chdat LE sy-datum
                AND chdat GE p_run.
    IF sy-subrc IS INITIAL.
*--------------------------------------------------------------------*
*      Logic to fetch Email ID:
*      1) Get Address number from BUT020
*      2) Pass BUT000-PERSNUMBER and BUT020-ADDRNUMBER to ADR6
*      3) Get email id
*      For SU01D also, we need to go to table ADR6. Thus, we will
*      fill up a common structure LT_ADDR_PERS here with BP details,
*      then with SU01D details, and at the end select data
*      collectively from table ADR6
*--------------------------------------------------------------------*
      SELECT  partner
              addrnumber
              FROM but020
              INTO TABLE me->t_but020
              FOR ALL ENTRIES IN me->t_but000
                WHERE partner EQ me->t_but000-partner.
      IF sy-subrc IS INITIAL.
        CLEAR: lt_addr_pers .
        LOOP AT me->t_but000 INTO lw_but000.
          READ TABLE me->t_but020 INTO lw_but020
            WITH KEY partner = lw_but000-partner.
          IF sy-subrc IS INITIAL.
            lw_addr_pers-addrnumber = lw_but020-addrnumber.
            lw_addr_pers-persnumber = lw_but000-persnumber.
            APPEND lw_addr_pers TO lt_addr_pers.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
*--------------------------------------------------------------------*
*    End of Business Partner data
*--------------------------------------------------------------------*

    me->get_user_id( ).

*--------------------------------------------------------------------*
*    Begin of SU01D data
*--------------------------------------------------------------------*
    IF me->t_user_ids IS NOT INITIAL.
      SELECT  bname
              name_first
              name_last
              FROM user_addr
              INTO TABLE me->t_user_addr
              FOR ALL ENTRIES IN me->t_user_ids
                WHERE bname EQ me->t_user_ids-bname.

      SELECT  bname
              persnumber
              addrnumber
              FROM usr21
              INTO TABLE me->t_usr21
              FOR ALL ENTRIES IN me->t_user_ids
                WHERE bname EQ me->t_user_ids-bname.
      IF sy-subrc IS INITIAL.
        LOOP AT me->t_usr21 INTO lw_usr21.
          lw_addr_pers-addrnumber = lw_usr21-addrnumber.
          lw_addr_pers-persnumber = lw_usr21-persnumber.
          APPEND lw_addr_pers TO lt_addr_pers.
        ENDLOOP.
      ENDIF.
    ENDIF.
*--------------------------------------------------------------------*
*    End of SU01D data
*--------------------------------------------------------------------*

    IF lt_addr_pers IS NOT INITIAL.
      SELECT  addrnumber
              persnumber
              smtp_addr
              FROM adr6
              INTO TABLE me->t_adr6
              FOR ALL ENTRIES IN lt_addr_pers
                WHERE addrnumber EQ lt_addr_pers-addrnumber
                  AND persnumber EQ lt_addr_pers-persnumber.
    ENDIF.
  ENDMETHOD.                    "get_data

  METHOD get_user_id.
    TYPES: BEGIN OF ltype_hrp1001,
            objid TYPE hrp1001-objid,
            sobid TYPE hrp1001-sobid,
           END OF ltype_hrp1001,

           BEGIN OF ltype_users,
             sobid TYPE hrp1001-sobid,
           END OF ltype_users.

    DATA: lt_objid TYPE STANDARD TABLE OF ltype_hrp1001,
          lt_sobid TYPE STANDARD TABLE OF ltype_users,
          lt_users TYPE STANDARD TABLE OF ltype_hrp1001.

    DATA: lw_sobid    TYPE ltype_users,
          lw_but000   TYPE me->type_but000,
          lw_objid    TYPE ltype_hrp1001,
          lw_users    TYPE ltype_hrp1001,
          lw_user_ids TYPE me->type_user_ids.

    LOOP AT me->t_but000 INTO lw_but000.
      lw_sobid-sobid = lw_but000-partner.
      APPEND lw_sobid TO lt_sobid.
    ENDLOOP.

    IF lt_sobid IS NOT INITIAL.
      SELECT  objid
              sobid
              FROM hrp1001
              INTO TABLE lt_objid
              FOR ALL ENTRIES IN lt_sobid
                WHERE otype EQ 'CP'
                  AND sobid EQ lt_sobid-sobid.
      IF sy-subrc IS INITIAL.
        SELECT  objid
                sobid
                FROM hrp1001
                INTO TABLE lt_users
                FOR ALL ENTRIES IN lt_objid
                  WHERE objid EQ lt_objid-objid
                    AND sclas EQ 'US'.
        IF sy-subrc IS INITIAL.
          LOOP AT me->t_but000 INTO lw_but000.
            READ TABLE lt_objid INTO lw_objid
              WITH KEY sobid = lw_but000-partner.
            IF sy-subrc IS INITIAL.
              READ TABLE lt_users INTO lw_users
                WITH KEY objid = lw_objid-objid.
              IF sy-subrc IS INITIAL.
                lw_user_ids-bname = lw_users-sobid.
                lw_user_ids-partner = lw_but000-partner.
                APPEND lw_user_ids TO me->t_user_ids.
              ENDIF.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.                    "get_user_id

  METHOD compare.
    DATA: lw_but000       TYPE me->type_but000,
          lw_but020       TYPE me->type_but020,
          lw_user_addr    TYPE me->type_user_addr,
          lw_adr6_master  TYPE me->type_adr6,
          lw_adr6_bp      TYPE me->type_adr6,
          lw_user_ids     TYPE me->type_user_ids,
          lw_usr21        TYPE me->type_usr21,
          lw_update_table TYPE me->type_update_table,
          lw_final_data   TYPE if_global_types=>type_final_output.

    CLEAR: me->t_update_table.
    LOOP AT me->t_but000 INTO lw_but000.
      READ TABLE me->t_user_ids INTO lw_user_ids
        WITH KEY partner = lw_but000-partner.
      IF sy-subrc IS INITIAL.
*--------------------------------------------------------------------*
*        Get first name and last name for SU01D
*--------------------------------------------------------------------*
        READ TABLE me->t_user_addr INTO lw_user_addr
          WITH KEY bname = lw_user_ids-bname.

        READ TABLE me->t_usr21 INTO lw_usr21
          WITH KEY bname = lw_user_ids-bname.
        IF sy-subrc IS INITIAL.
          READ TABLE me->t_adr6 INTO lw_adr6_master
            WITH KEY addrnumber = lw_usr21-addrnumber
                     persnumber = lw_usr21-persnumber.
        ENDIF.
      ENDIF.
*--------------------------------------------------------------------*
*        Get address number for Business Partner to get BP email
*--------------------------------------------------------------------*
      READ TABLE me->t_but020 INTO lw_but020
        WITH KEY partner = lw_but000-partner.
      IF sy-subrc IS INITIAL .
        READ TABLE me->t_adr6 INTO lw_adr6_bp
          WITH KEY addrnumber = lw_but020-addrnumber
                   persnumber = lw_but000-persnumber.
      ENDIF.

*--------------------------------------------------------------------*
*      Main comparison
*--------------------------------------------------------------------*
      CLEAR: lw_update_table, lw_final_data.
      lw_update_table-bname = lw_user_addr-bname.
      IF lw_but000-name_first NE lw_user_addr-name_first.
        lw_update_table-name_first = lw_but000-name_first.
        lw_final_data-old_name_first = lw_user_addr-name_first.
        lw_final_data-new_name_first = lw_but000-name_first.
      ENDIF.
      IF lw_but000-name_last NE lw_user_addr-name_last.
        lw_update_table-name_last = lw_but000-name_last.
        lw_final_data-old_name_last = lw_user_addr-name_last.
        lw_final_data-new_name_last = lw_but000-name_last.
      ENDIF.
      IF lw_adr6_bp-smtp_addr NE lw_adr6_master-smtp_addr.
        lw_update_table-smtp_addr = lw_adr6_bp-smtp_addr.
        lw_final_data-old_email = lw_adr6_master-smtp_addr.
        lw_final_data-new_email = lw_adr6_bp-smtp_addr.
      ENDIF.
      APPEND lw_update_table TO me->t_update_table.
      IF lw_final_data IS NOT INITIAL.
        lw_final_data-bname = lw_user_addr-bname.
        lw_final_data-partner = lw_but000-partner.
        APPEND lw_final_data TO me->t_final_output.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.                    "compare

  METHOD update.
    DATA: lw_update_table TYPE me->type_update_table,
          lw_address      TYPE bapiaddr3,
          lw_addressx     TYPE bapiaddr3x,
          lw_adcomx       TYPE bapiadcomx,
          lw_addsmtp      TYPE bapiadsmtp.
    DATA: lt_addsmtp TYPE STANDARD TABLE OF bapiadsmtp,
          lt_return  TYPE STANDARD TABLE OF bapiret2.

    LOOP AT me->t_update_table INTO lw_update_table.
      IF lw_update_table-name_first IS NOT INITIAL.
        lw_address-firstname = lw_update_table-name_first.
        lw_addressx-firstname = abap_true.
      ENDIF.
      IF lw_update_table-name_last IS NOT INITIAL.
        lw_address-lastname = lw_update_table-name_last.
        lw_addressx-lastname = abap_true.
      ENDIF.
      IF lw_update_table-smtp_addr IS NOT INITIAL.
        lw_addsmtp-e_mail = lw_update_table-smtp_addr.
        APPEND lw_addsmtp TO lt_addsmtp.
        lw_adcomx-adsmtp = abap_true.
      ENDIF.
      CALL FUNCTION 'BAPI_USER_CHANGE'
        EXPORTING
          username = lw_update_table-bname
          address  = lw_address
          addressx = lw_addressx
          addcomx  = lw_adcomx
        TABLES
          return   = lt_return
          addsmtp  = lt_addsmtp.
      CLEAR: lw_address, lw_addressx, lw_adcomx, lt_addsmtp, lw_addsmtp, lt_return.
    ENDLOOP.
  ENDMETHOD.                    "update

  METHOD get_final_data.
    rt_final_data = me->t_final_output.
  ENDMETHOD.                    "get_final_data
ENDCLASS.                    "cl_report IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS cl_email IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS cl_email IMPLEMENTATION.
  METHOD constructor.
    t_final_data = it_final_data.
  ENDMETHOD.                    "constructor

  METHOD begin.
    me->prepare_attachment( ).
    me->prepare_email_body( ).
    me->prepare_bcs_structures( ).
    me->send_email( ).
  ENDMETHOD.                    "begin

  METHOD prepare_attachment.
    DATA: lw_final_data LIKE LINE OF me->t_final_data.
    DATA: lv_temp_attachment TYPE string.
*--------------------------------------------------------------------*
*    Begin Excel Header
*--------------------------------------------------------------------*
    CONCATENATE 'User ID'
                'Business Partner'
                'Old First Name'
                'New First Name'
                'Old Last Name'
                'New Last Name'
                'Old Email'
                'New Email'
                INTO me->v_attachment
                SEPARATED BY me->c_tab.
*--------------------------------------------------------------------*
*    End Excel Header
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*    Begin Excel content
*--------------------------------------------------------------------*
    LOOP AT me->t_final_data INTO lw_final_data.
      CONCATENATE lw_final_data-bname
                  lw_final_data-partner
                  lw_final_data-old_name_first
                  lw_final_data-new_name_first
                  lw_final_data-old_name_last
                  lw_final_data-new_name_last
                  lw_final_data-old_email
                  lw_final_data-new_email
                  INTO lv_temp_attachment
                  SEPARATED BY me->c_tab.

      CONCATENATE me->v_attachment lv_temp_attachment
                  INTO me->v_attachment
                  SEPARATED BY me->c_cr.
    ENDLOOP.
*--------------------------------------------------------------------*
*    End Excel content
*--------------------------------------------------------------------*
    cl_bcs_convert=>string_to_solix(
                                    EXPORTING
                                      iv_string = me->v_attachment
                                      iv_codepage = '4103' "suitable for MS Excel, leave empty
                                      iv_add_bom = 'X' "for other doc types
                                    IMPORTING
                                      et_solix = me->t_binary_content
                                      ev_size = me->v_size ).
  ENDMETHOD.                    "prepare_attachment

  METHOD prepare_email_body.
    DATA: lw_mail_body LIKE LINE OF me->t_mail_body,
          lv_date      TYPE string,
          lv_time      TYPE string.

    lw_mail_body = '<b>Dear Team,</b>'.
    APPEND lw_mail_body TO me->t_mail_body.
    CLEAR: lw_mail_body.

    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal = sy-datum
      IMPORTING
        date_external = lv_date.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    CONCATENATE sy-uzeit+0(2)
                sy-uzeit+2(2)
                sy-uzeit+4(2) INTO lv_time SEPARATED BY ':'.

    CONCATENATE 'User Sync program executed on'
                lv_date
                ':'
                lv_time
                'and updated First name, Last name and Email ID where system found difference in SRM Business Partner. List is as attached for your information.'
                INTO lw_mail_body
                SEPARATED BY space.
    APPEND lw_mail_body TO me->t_mail_body.
    CLEAR lw_mail_body.
  ENDMETHOD.                    "prepare_email_body

  METHOD prepare_bcs_structures.
    DATA: lv_subject TYPE so_obj_des.
*--------------------------------------------------------------------*
*    Create document
*--------------------------------------------------------------------*
    me->o_send_request = cl_bcs=>create_persistent( ).
    CONCATENATE sy-sysid 'SRM USER ID Synch Update' INTO lv_subject
      SEPARATED BY space.
    CALL METHOD cl_document_bcs=>create_document
      EXPORTING
        i_type    = 'HTM'
*       i_subject = 'Workday User Data Sync'
        i_subject = lv_subject
*       i_length  = l_text_length
        i_text    = me->t_mail_body
      RECEIVING
        result    = me->o_document.

*--------------------------------------------------------------------*
*    Set sender
*--------------------------------------------------------------------*
    me->o_sender = cl_sapuser_bcs=>create( sy-uname ).
    me->o_send_request->set_sender( i_sender = me->o_sender ).

    CALL METHOD me->o_document->add_attachment(
      i_attachment_type = 'XLS'
      i_attachment_subject = 'User Data Sync'
      i_attachment_size = me->v_size
      i_att_content_hex = me->t_binary_content ).

    me->o_send_request->set_document( me->o_document ).

*--------------------------------------------------------------------*
*    Set Recipients
*--------------------------------------------------------------------*
    me->o_recipent = cl_cam_address_bcs=>create_internet_address( 'taha.farosh@kraftheinz.com' ).
    me->o_send_request->add_recipient( i_recipient = me->o_recipent ).
  ENDMETHOD.                    "prepare_bcs_structures

  METHOD send_email.
    me->o_send_request->set_send_immediately( 'X' ).
    me->o_send_request->send( ).

    COMMIT WORK AND WAIT.
  ENDMETHOD.                    "send_email
ENDCLASS.                    "cl_email IMPLEMENTATION
