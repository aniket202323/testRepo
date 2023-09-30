Create Procedure dbo.spDBR_Export_Template_XSL_Files
@template_id int
AS
 	 create table #Template_XSL_Files
 	 (
 	  	 CreateFile int default 0,
 	  	 Dashboard_Template_XSL_Filename varchar(100),
 	  	 Dashboard_Template_ID int default -1
/* 	  	 Dashboard_Template_XSL text 	 
*/ 	 )
 	 create table #Dashboard_Templates
 	 (
 	  	 Dashboard_Template_ID int,
 	  	 Dashboard_Template_XSL_FileName varchar(100),
/* 	  	 Dashboard_Template_XSL text,
*/ 	  	 type int
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
 	  	  	 and (dashboard_template_link_from in
 	  	  	  	 (select dashboard_template_link_to from #dashboard_Template_links))
 	  	 set @newrowcount = (select count(dashboard_template_link_to) from #dashboard_template_links)
 	 end
 	 
 	 insert into #Dashboard_Templates 
 	 (Dashboard_Template_ID, Dashboard_Template_XSL_FileName, /*Dashboard_Template_XSL,*/type) 
 	 select t.dashboard_Template_id, t.dashboard_template_xsl_filename, /*t.dashboard_template_xsl,*/ t.type from dashboard_templates t where t.dashboard_template_id in (select distinct(dashboard_template_link_to) from #dashboard_template_links)
 	 
 	 set @newrowcount = (select count(dashboard_Template_link_id) from #dashboard_template_links where dashboard_Template_link_to = @template_id)
 	 
 	 if (@newrowcount = 0)
 	 begin
 	  	 insert into #Dashboard_Templates (Dashboard_Template_ID, Dashboard_Template_XSL_FileName, /*Dashboard_Template_XSL,*/ type) select t.dashboard_Template_id, t.dashboard_template_xsl_filename, /*t.dashboard_template_xsl,*/ t.type from dashboard_templates t where t.dashboard_template_id = @template_id
 	 end 	  	 
 	 
 	 insert into #Template_XSL_Files (createfile, dashboard_template_xsl_filename, dashboard_template_id) select 1, dashboard_template_xsl_filename,  dashboard_template_id from #Dashboard_Templates where not dashboard_template_xsl_filename = 'None' and type = 1
 	 insert into #Template_XSL_Files ( dashboard_template_xsl_filename) select distinct(dashboard_template_xsl_filename) from #Dashboard_Templates where not dashboard_template_xsl_filename = 'None' and type = 2
 	 select * from #Template_XSL_Files
 	 
 	 
 	 
