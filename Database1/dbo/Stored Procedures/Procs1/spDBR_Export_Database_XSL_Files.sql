Create Procedure dbo.spDBR_Export_Database_XSL_Files
AS
 	 create table #Template_XSL_Files
 	 (
 	  	 CreateFile int default 0,
 	  	 Dashboard_Template_XSL_Filename varchar(100),
 	  	 Dashboard_Template_ID int default -1
 	 )
 	 insert into #Template_XSL_Files (createfile, dashboard_template_xsl_filename, dashboard_template_id) select 1, dashboard_template_xsl_filename,  dashboard_template_id from Dashboard_Templates where not dashboard_template_xsl_filename = 'None' and type = 1
 	 insert into #Template_XSL_Files ( dashboard_template_xsl_filename) select distinct(dashboard_template_xsl_filename) from Dashboard_Templates where not dashboard_template_xsl_filename = 'None' and type = 2
 	 select * from #Template_XSL_Files
 	 
 	 
 	 
