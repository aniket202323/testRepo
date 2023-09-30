Create Procedure dbo.spDBR_Export_Database_Reports
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 create table #Dashboard_Parameter_Values
 	 (
 	  	 Dashboard_Parameter_Value_ID int,
 	  	 Dashboard_Report_ID int,
 	  	 Dashboard_Template_Parameter_ID int,
 	  	 Dashboard_Parameter_Row int,
 	  	 Dashboard_Parameter_Column int,
 	  	 Dashboard_Parameter_Value varchar(4000)
 	 )
 	 create table #Dashboard_Report_Links
 	 (
 	  	 Dashboard_Report_Link_ID int,
 	  	 Dashboard_Template_Link_ID int,
 	  	 Dashboard_Report_From_ID int,
 	  	 Dashboard_Report_To_ID int
 	 )
 	 create table #Dashboard_Reports
 	 (
 	  	 dashboard_report_id int,
 	  	 dashboard_template_id int,
 	  	 dashboard_report_version_count int,
 	  	 dashboard_report_ad_hoc_flag bit,
 	  	 dashboard_session_id int,
 	  	 dashboard_report_security_group_id int,
 	  	 dashboard_report_server varchar(100),
 	  	 dashboard_report_number_hits int,
 	  	 dashboard_report_description varchar(4000),
 	  	 dashboard_report_create_date datetime,
 	  	 dashboard_report_column int,
 	  	 dashboard_report_column_position int,
 	  	 dashboard_report_has_frame int,
 	  	 dashboard_report_expanded int,
 	  	 dashboard_reporT_allow_remove int,
 	  	 dashboard_report_allow_minimize int,
 	  	 dashboard_report_cache_code int,
 	  	 dashboard_report_cache_timeout int,
 	  	 dashboard_report_detail_link varchar(500),
 	  	 dashboard_report_help_link varchar(500),
 	  	 dashboard_report_name varchar(100),
 	  	 version int
 	 )
 	 insert into #dashboard_reports select dashboard_report_id, dashboard_template_id, dashboard_report_version_count, dashboard_report_ad_hoc_flag,
 	  	 dashboard_session_id, dashboard_report_security_group_id, dashboard_report_server, dashboard_report_number_hits, dashboard_report_description,
 	  	 dashboard_report_create_date, dashboard_report_column, dashboard_report_column_position, dashboard_report_has_frame, dashboard_report_expanded,
 	  	 dashboard_report_allow_remove, dashboard_report_allow_minimize, dashboard_report_cache_code, dashboard_report_cache_timeout, dashboard_report_detail_link,
 	  	 dashboard_report_help_link, dashboard_report_name, version  from dashboard_reports where dashboard_Report_ad_hoc_flag = 0
 	 insert into #Dashboard_Report_Links select l.dashboard_report_Link_id, l.dashboard_template_link_id, l.dashboarD_report_from_id, l.dashboard_report_to_id from dashboard_report_links l, dashboard_Reports r
 	 where l.dashboard_report_from_id = r.dashboard_report_id and r.dashboard_report_ad_hoc_flag = 0
 	 insert into #Dashboard_Parameter_Values select p.dashboard_parameter_value_id, p.dashboard_report_id, p.dashboard_template_parameter_id, p.dashboard_parameter_row,
 	  	 p.dashboard_parameter_column, p.dashboard_parameter_value from dashboard_parameter_values p, dashboard_reports r
 	  	 where p.dashboard_report_id = r.dashboard_report_id and r.dashboard_report_ad_hoc_flag = 0
 	 ---23/08/2010 - Update datetime formate in UTC into #Dashboard_Reports table
 	 Update #Dashboard_Reports Set dashboard_report_create_date = dbo.fnServer_CmnConvertFromDBTime(dashboard_report_create_date,@InTimeZone)
 	 select * from #Dashboard_Reports for xml auto
 	 
 	 select * from #Dashboard_Report_Links for xml auto
 	 select * from #Dashboard_Parameter_Values for xml auto
 	 
