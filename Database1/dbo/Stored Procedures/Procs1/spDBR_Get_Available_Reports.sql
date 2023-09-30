Create Procedure dbo.spDBR_Get_Available_Reports
@dbuid int,
@pageid int,
@querystring varchar(100)
AS
 	 declare @groupid int
 	 declare @userid int
 	 
 	 set @userid = (select user_id from dashboard_users where dashboard_user_id = @dbuid)
 	 set @groupid = (select group_id from user_security where user_id = @userid)
 	 
 	 if (@querystring = '')
 	 begin
 	  	 select r.dashboard_report_id, r.dashboard_report_name 
 	  	  	 from dashboard_reports r
 	  	  	 where (r.dashboard_report_security_group_id = @groupid or r.dashboard_report_security_group_id is null)
 	  	  	  	 and r.dashboard_report_id not in (select dashboard_report_id from dashboard_parts where dashboard_page_id = @pageid)
 	  	  	  	 and r.dashboard_report_ad_hoc_flag = 0
 	  	  	  	 order by r.dashboard_report_name
 	  	  	  	 
 	  	 /* 	  	 
 	  	 select r.dashboard_report_id, r.dashboard_report_name 
 	  	  	 from dashboard_reports r, dashboard_session s
 	  	  	 where (r.dashboard_report_security_group_id = @groupid or r.dashboard_report_security_group_id is null)
 	  	  	  	 and r.dashboard_report_id not in (select dashboard_report_id from dashboard_parts where dashboard_page_id = @pageid)
 	  	  	  	 and r.dashboard_report_ad_hoc_flag = 1 and r.dashboard_session_id = s.dashboard_session_id and s.dashboard_user_id = @dbuid
 	  	 */ 	  	 
 	 end 	  	 
 	 else
 	 begin
 	  	 set @querystring = (@querystring + '%')
 	  	  	 select r.dashboard_report_id, r.dashboard_report_name 
 	  	  	 from dashboard_reports r
 	  	  	 where (r.dashboard_report_security_group_id = @groupid or r.dashboard_report_security_group_id is null)
 	  	  	  	 and r.dashboard_report_name like @querystring
 	  	  	  	 and r.dashboard_report_id not in (select dashboard_report_id from dashboard_parts where dashboard_page_id = @pageid)
 	  	  	  	 and r.dashboard_report_ad_hoc_flag = 0
 	  	  	  	 order by r.dashboard_report_name
 	  	  	  	 
 	  	 /* 	 select r.dashboard_report_id, r.dashboard_report_name 
 	  	  	 from dashboard_reports r, dashboard_session s
 	  	  	 where (r.dashboard_report_security_group_id = @groupid or r.dashboard_report_security_group_id is null)
 	  	  	  	 and r.dashboard_report_name like @querystring
 	  	  	  	 and r.dashboard_report_id not in (select dashboard_report_id from dashboard_parts where dashboard_page_id = @pageid)
 	  	  	  	 and r.dashboard_report_ad_hoc_flag = 1 and r.dashboard_session_id = s.dashboard_session_id and s.dashboard_user_id = @dbuid
 	  	  	  	 order by r.dashboard_report_name
*/
 	 end
