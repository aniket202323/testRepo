CREATE PROCEDURE dbo.spRS_UnInstall  --'USGB039',2
@ServerName varchar(20),
@Function int  
AS
Declare @FullUninstall integer
Declare @LocalServer varchar(20)
Select @LocalServer = Value from site_parameters where parm_id = 55
If @LocalServer = @ServerName and @Function = 1
  Select @FullUnInstall = 1
Else
  Select @FullUnInstall = 0
-------------------------------------
-- Always Clean The Activity Tables
-------------------------------------
--Truncate Table Report_Runs
--Truncate Table Report_Engine_Activity
--When run as comxclient, not authority to truncate
Delete Report_Runs
Delete Report_Engine_Activity 
 	 
If @FullUnInstall = 1
  Begin
    -- UNINSTALL EVERYTHING
    Delete from Report_Engines
    Delete from CXS_Service where ntservice_name like 'profeng%'
    Delete from CXS_Service where ntservice_name like 'profpdf%'
    Delete from CXS_Service where ntservice_name like 'profsch%'
    Delete from CXS_Service where ntservice_name like 'prdb%'
    Delete from CXS_Service where ntservice_name like 'prasp%'
    Delete from User_Parameters where User_Id in (22,23,24,25,36)
    Delete from Site_Parameters where parm_Id in (50,51,52,53,55,56,57,58,59)
    Update Site_Parameters set value = ' ' where parm_id = 10
  End
Else
  Begin
    -- UNINSTALL REPORT ENGINES
    Delete from report_engines Where Engine_Name = @ServerName
    Delete from cxs_service where Node_Name = @ServerName and (ntservice_name like 'profeng%' or ntservice_name like 'profpdf%')
    Delete from user_parameters where user_Id in (22,23,24,25) and hostname = @ServerName
  End
/*
-- UNINSTALL REPORT ENGINES
If @Function = 1
  Begin
    Delete from Report_Runs
    Delete from Report_Engine_Activity Where LTrim(RTrim(Upper(Engine_Name))) like LTrim(RTrim(Upper(@ServerName)))
    Delete from report_engines Where LTrim(RTrim(Upper(Engine_Name))) like LTrim(RTrim(Upper(@ServerName)))
    Delete from cxs_service where lower(ntservice_name) like 'profeng%' and LTrim(RTrim(Upper(Node_Name))) like LTrim(RTrim(Upper(@ServerName)))
    Delete from user_parameters where user_Id in (22,23,24,25) and upper(hostname) like LTrim(RTrim(Upper(@ServerName)))
  End
-- UNINSTALL THE WEB SITE
If @Function = 2
  Begin
    Delete from site_parameters where parm_Id in (52,53,55,56)
    Update Site_Parameters set value = ' ' where parm_id = 10
  End
-- UNINSTALL THE REPORT ENGINES AND WEB SITE
If @Function = 3
  Begin
    Delete from Report_Runs
    Delete from Report_Engine_Activity Where LTrim(RTrim(Upper(Engine_Name))) like LTrim(RTrim(Upper(@ServerName)))
    Delete from report_engines Where LTrim(RTrim(Upper(Engine_Name))) like LTrim(RTrim(Upper(@ServerName)))
    Delete from cxs_service where lower(ntservice_name) like 'profeng%' and LTrim(RTrim(Upper(Node_Name))) like LTrim(RTrim(Upper(@ServerName)))
    Delete from user_parameters where user_Id in (22,23,24,25) and upper(hostname) like LTrim(RTrim(Upper(@ServerName)))
    Delete from site_parameters where parm_Id in (52,53,55,56)
    Update Site_Parameters set value = ' ' where parm_id = 10
  End
*/
