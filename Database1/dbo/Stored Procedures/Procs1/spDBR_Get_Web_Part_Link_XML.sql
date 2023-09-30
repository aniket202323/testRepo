Create Procedure dbo.spDBR_Get_Web_Part_Link_XML
@ReportID int
AS
create table #links
(
 	 dashboard_template_name varchar(50),
 	 dashboard_report_name varchar(50),
 	 dashboard_report_to_id int,
 	 dashboard_template_id int,
 	 /*dashboard_icon_name varchar(50),*/
 	 dashboard_template_launch_type int,
 	 dashboard_template_fixed_height bit,
 	 dashboard_template_fixed_width bit,
 	 dashboard_template_height int,
 	 dashboard_template_width int
)
insert into #links select t.dashboard_template_name, 
 	  	 dr.dashboard_report_name,
 	  	 r.dashboard_report_to_id,  
 	  	 t.dashboard_template_id, 
/* 	  	 i.dashboard_icon_name, */
 	  	 t.dashboard_template_launch_Type,
 	  	 t.dashboard_template_fixed_height,
 	  	 t.dashboard_template_fixed_width,
 	  	 t.height,
 	  	 t.width 
 	 from dashboard_templates t, dashboard_report_links r, dashboard_template_links tl, /*dashboard_icons i,*/ dashboard_reports dr 
 	  	 where /*i.dashboard_icon_id = t.dashboard_icon_id and*/ r.dashboard_report_from_id = @ReportID 
 	  	  	 and r.dashboard_template_link_id = tl.dashboard_template_link_id
 	  	  	 and  t.dashboard_template_id = tl.dashboard_template_link_to
 	  	  	 and dr.dashboard_report_id = r.dashboard_report_to_id 
 	 
 	 insert into #links select t.dashboard_template_name, 
 	  	 null,
 	  	 r.dashboard_report_to_id,  
 	  	 t.dashboard_template_id, 
 	  	 /*i.dashboard_icon_name,*/ 
 	  	 t.dashboard_template_launch_Type,
 	  	 t.dashboard_template_fixed_height,
 	  	 t.dashboard_template_fixed_width,
 	  	 t.height,
 	  	 t.width 
 	 from dashboard_templates t, dashboard_report_links r, dashboard_template_links tl/*, dashboard_icons i*/ 
 	  	 where /*i.dashboard_icon_id = t.dashboard_icon_id and */r.dashboard_report_from_id = @ReportID 
 	  	  	 and r.dashboard_template_link_id = tl.dashboard_template_link_id
 	  	  	 and  t.dashboard_template_id = tl.dashboard_template_link_to
 	  	  	 and r.dashboard_report_to_id is null 
 	  	  	 
 	 select * from #links
 	 drop table #links
 	  	  	 
