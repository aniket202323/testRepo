Create Procedure dbo.spDBR_Export_Database_Templates
@locktemplates bit = 0
AS
 	 create table #Dashboard_Templates
 	 (
 	  	 Dashboard_Template_ID int,
 	  	 Dashboard_Template_Name varchar(100),
 	  	 Dashboard_Template_XSL_Filename varchar(100),
 	  	 Dashboard_Template_Preview_Filename varchar(100),
 	  	 Dashboard_Template_Build int,
 	  	 Dashboard_Template_Locked int,
 	  	 Dashboard_Template_Launch_Type int,
 	  	 Dashboard_Template_Procedure varchar(100),
 	  	 Dashboard_Template_Size_Unit int,
 	  	 Dashboard_Template_Description varchar(4000),
 	  	 Dashboard_Template_Column int,
 	  	 Dashboard_Template_Column_Position int,
 	  	 Dashboard_Template_Has_Frame int,
 	  	 Dashboard_Template_Expanded int,
 	  	 Dashboard_Template_Allow_Remove int,
 	  	 Dashboard_Template_Allow_Minimize int,
 	  	 Dashboard_Template_Cache_Code int,
 	  	 Dashboard_Template_Cache_Timeout int,
 	  	 Dashboard_Template_Detail_Link varchar(500),
 	  	 Dashboard_Template_Help_Link varchar(500),
 	  	 version int,
 	  	 Height int,
 	  	 Width int,
 	  	 type int,
 	  	 dashboard_template_fixed_height bit,
 	  	 dashboard_template_fixed_width bit,
 	  	 basetemplate bit
 	 )
 	 insert into #Dashboard_Templates select 	 Dashboard_Template_ID,Dashboard_Template_Name,Dashboard_Template_XSL_Filename, Dashboard_Template_Preview_Filename,
 	  	 Dashboard_Template_Build,Dashboard_Template_Locked,Dashboard_Template_Launch_Type, 	 
 	  	 Dashboard_Template_Procedure,Dashboard_Template_Size_Unit,Dashboard_Template_Description, 	 
 	  	 Dashboard_Template_Column,Dashboard_Template_Column_Position,Dashboard_Template_Has_Frame,Dashboard_Template_Expanded,Dashboard_Template_Allow_Remove,Dashboard_Template_Allow_Minimize,Dashboard_Template_Cache_Code,Dashboard_Template_Cache_Timeout,Dashboard_Template_Detail_Link,Dashboard_Template_Help_Link,version,Height, 	 Width,type, dashboard_template_fixed_height, dashboard_template_fixed_width, basetemplate 
 	  	  	 from dashboard_templates
 	 update #dashboard_templates set dashboard_template_xsl_filename = '[UNPROCESSED TEMPLATE IMPORT]' + dashboard_template_xsl_filename
 	 update #dashboard_templates set dashboard_template_preview_filename = '[UNPROCESSED TEMPLATE IMPORT]' + dashboard_template_preview_filename
 	 if (@locktemplates = 1)
 	 begin
 	  	 update #dashboard_templates set dashboard_template_locked = @locktemplates
 	 end
 	 select * from #Dashboard_Templates for xml auto
 	 
