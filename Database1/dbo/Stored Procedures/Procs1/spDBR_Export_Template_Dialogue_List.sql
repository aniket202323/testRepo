Create Procedure dbo.spDBR_Export_Template_Dialogue_List
@template_id int
AS
 	 
 	 create table #Dashboard_Dialogues
 	 (
 	  	 URL varchar(1000),
 	 )
 	 create table #Dashboard_Templates
 	 (
 	  	 Dashboard_Template_ID int,
 	 )
 	 create table #Dashboard_Template_Parameters
 	 (
 	  	 Dashboard_Template_Parameter_ID int,
 	 )
 	 create table #Dashboard_Template_Dialogue_Parameters
 	 (
 	  	 Dashboard_Dialogue_ID int,
 	 )
 	 create table #Dashboard_Template_Links
 	 (
 	  	 Dashboard_Template_Link_ID int,
 	  	 Dashboard_Template_Link_From int,
 	  	 Dashboard_Template_Link_To int 
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
 	 
 	 insert into #Dashboard_Templates (Dashboard_Template_ID)
 	 select  	 t.Dashboard_Template_ID
 	  	 from dashboard_templates t where t.dashboard_template_id in (select distinct(dashboard_template_link_to) from #dashboard_template_links)
 	 
 	 set @newrowcount = (select count(dashboard_Template_link_id) from #dashboard_template_links where dashboard_Template_link_to = @template_id)
 	 
 	 if (@newrowcount = 0)
 	 begin
 	  	 insert into #Dashboard_Templates (Dashboard_Template_ID) 	 
 	  	 select t.Dashboard_Template_ID
 	  	 from dashboard_templates t where t.dashboard_template_id = @template_id
 	 end
 	 
 	 
 	 insert into #Dashboard_Template_Parameters (Dashboard_Template_Parameter_ID)
 	  select p.Dashboard_Template_Parameter_ID
 	  	  from dashboard_template_parameters p, #dashboard_templates t where p.dashboard_template_id = t.dashboard_template_id
 	 insert into #Dashboard_Template_Dialogue_Parameters (Dashboard_Dialogue_ID) 
 	  select dp.Dashboard_Dialogue_ID
 	  from dashboard_template_dialogue_parameters dp, #dashboard_template_parameters p where dp.dashboard_template_parameter_id = p.dashboard_template_parameter_id
 	 insert into #Dashboard_Dialogues (URL)
 	 select URL
 	 from dashboard_dialogues d where d.dashboard_dialogue_id in (select distinct(dashboard_dialogue_id) from #dashboard_template_dialogue_parameters)
 	  	 
 	 select url from #dashboard_dialogues
 	 
