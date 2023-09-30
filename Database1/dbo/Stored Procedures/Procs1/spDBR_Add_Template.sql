Create Procedure dbo.spDBR_Add_Template
@template_name varchar(100)
AS
 	 declare @templateid int
/* 	 declare @iconid int
*/ 	 declare @count int
 	 declare @version int
 	 set @version = 1
 	 set @count = (select count(dashboard_template_id) from dashboard_templates where dashboard_template_name = @template_name)
 	 if (@count > 0)
 	 begin
 	  	 set @version = (select max(version) from dashboard_templates where dashboard_template_name = @template_name) + 1
 	 end 	 
/* 	 set @iconid = (select min(dashboard_icon_id) from dashboard_icons)
*/ 	 
 	 insert into Dashboard_Templates (Dashboard_Template_Name, Dashboard_Template_XSL, Dashboard_Template_XSL_Filename, Dashboard_Template_Preview, 
 	  	  	  	  	  	  	  	  	 Dashboard_Template_Preview_Filename, Dashboard_Template_Build, Dashboard_Template_Locked,
 	  	  	  	  	  	  	  	  	 Dashboard_Template_Size_Unit,Dashboard_Template_Fixed_Height, Dashboard_Template_Fixed_Width, Dashboard_Template_Launch_Type, Dashboard_Icon_ID, 
 	  	  	  	  	  	  	  	  	 Dashboard_Template_Column, Dashboard_Template_Column_Position, dashboard_template_has_frame, 
 	  	  	  	  	  	  	  	  	 dashboard_template_expanded, dashboard_template_allow_remove, dashboard_template_allow_minimize, 
 	  	  	  	  	  	  	  	  	 dashboard_template_cache_code, dashboard_template_cache_timeout, height, width, version)
 	  	  	  	  	  	  	  	  	  values (@template_name, 'None', 'None', 'None', 'None',1,0,1,0,0, 1, null,1,1,1,0, 1, 1, 0, 0,0,0, @version)
 	 
 	 set @templateid =  (select scope_identity())
/* 	 update dashboarD_templates set dashboard_template_xsl = (select xsl from dashboard_default_xsl) where dashboard_template_id = @templateid
 	 */
 	 select @templateid as id
 	 
