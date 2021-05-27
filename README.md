# SRM-User-Update-Report

In the current design, there is no automatic program to update SU01D user master data. 

In some scenarios, employee data are being updated from Workday to EE9 and the same is being updated in SRM. 

However, the data is being updated only in BP (Business Partner) entries i.e. BUT000 table and it is not being updated in SU01D master data tables (USER_ADDR). This is causing discrepancies in the employee data in the SRM portal. In addition, approvers are seeing discrepancies in their names in SRM approval mail notifications.

This program is built to update SU01D user master data whenever there is a update in Business Partner data (table - BUT000).
