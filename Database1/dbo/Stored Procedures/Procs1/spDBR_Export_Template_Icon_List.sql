Create Procedure dbo.spDBR_Export_Template_Icon_List
@template_id int
AS
 	 
 	 create table #Dashboard_Parameter_Types
 	 (
 	  	 Dashboard_Parameter_Type_ID int,
 	  	 Dashboard_Icon_Id int
 	 )
 	 
 	 create table #Dashboard_Templates
 	 (
 	  	 Dashboard_Template_ID int,
 	  	 Dashboard_Icon_ID int
 	 )
 	 create table #Dashboard_Template_Parameters
 	 (
 	  	 Dashboard_Parameter_Type_ID int
 	 )
 	 
 	 create table #Dashboard_Template_Links
 	 (
 	  	 Dashboard_Template_Link_ID int,
 	  	 Dashboard_Template_Link_From int,
 	  	 Dashboard_Template_Link_To int 
 	 )
 	 create table #Dashboard_Icons
 	 (
 	  	 Dashboard_Icon_ID int
 	 )
 	 
 	 declare @oldrowcount int
 	 set @oldrowcount = 0
 	 declare @newrowcount int
 	 
 	 insert into #Dashboard_Template_Links (dashboard_template_link_id, dashboard_template_link_from, dashboard_template_link_to) select dashboard_template_link_id, dashboard_template_link_from, dashboard_template_link_to from dashboard_Template_links where Dashboard_Template_Link_From = @template_id
 	 
 	 set @newrowcount = (select count(dashboard_template_link_to) from #dashboard_template_links)
 	 
 	 while (@newrowcount > @oldrowcount)
 	 begin
 	  	 set @oldrowcount = @newrowcount
 	  	 insert into #dashboard_template_links (dashboard_template_link_id, dashboard_template_link_from, dashboard_template_link_to) select dashboard_template_link_id, dashboard_template_link_from, dashboard_template_link_to from dashboard_template_links where (not dashboard_template_link_from = @template_id) 
 	  	  	 and (not dashboard_template_link_from in (select dashboard_template_link_from from #dashboard_Template_links))
 	  	 set @newrowcount = (select count(dashboard_template_link_to) from #dashboard_template_links)
 	 end
 	 
 	 insert into #Dashboard_Templates (Dashboard_Template_ID, Dashboard_Icon_ID) select t.dashboard_template_id, t.dashboarD_icon_id from dashboard_templates t where t.dashboard_template_id in (select distinct(dashboard_template_link_to) from #dashboard_template_links)
 	 
 	 set @newrowcount = (select count(dashboard_Template_link_id) from #dashboard_template_links where dashboard_Template_link_to = @template_id)
 	 
 	 if (@newrowcount = 0)
 	 begin
 	  	 insert into #Dashboard_Templates (Dashboard_Template_ID, Dashboard_Icon_ID) select dashboard_template_id, dashboard_icon_id from dashboard_templates where dashboard_template_id = @template_id
 	 end
 	 
 	 insert into #Dashboard_Template_Parameters (Dashboard_Parameter_Type_ID) select p.dashboard_parameter_type_id from dashboard_template_parameters p, #dashboard_templates t where p.dashboard_template_id = t.dashboard_template_id
 	 insert into #Dashboard_Parameter_Types (Dashboard_Parameter_Type_ID, dashboard_icon_id) select pt.dashboard_parameter_type_id, pt.dashboard_icon_id from dashboard_parameter_types pt where pt.dashboard_parameter_type_id in (select distinct(dashboard_parameter_type_id) from #dashboard_template_parameters)
 	 insert into #Dashboard_Icons (dashboard_icon_id) select i.dashboard_icon_id from dashboard_icons i where
 	 i.dashboard_icon_id in (select distinct(dashboard_icon_id) from #dashboard_templates) or
 	 i.dashboard_icon_id in (select distinct(dashboard_icon_id) from #dashboard_parameter_types)
 	 
 	 
 	 select dashboard_icon_id from #dashboard_icons
 	 
