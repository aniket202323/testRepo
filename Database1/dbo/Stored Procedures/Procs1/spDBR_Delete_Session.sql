Create Procedure dbo.spDBR_Delete_Session
@sessionid int
AS
declare @reportid int
set @reportid = (select min(dashboard_report_id) from dashboard_reports where dashboard_session_id = @sessionid)
while (not @reportid is null)
begin
 	 EXECUTE spDBR_Delete_Report @reportid
 	 set @reportid = (select min(dashboard_report_id) from dashboard_reports where dashboard_session_id = @sessionid)
end 
 	 
delete from Dashboard_Session where Dashboard_Session_ID = @sessionid
