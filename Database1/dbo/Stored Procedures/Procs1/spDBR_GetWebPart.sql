Create Procedure dbo.spDBR_GetWebPart
@ReportID int = 2800,     --should be (2789 is test)
@ReportFromID int = 0,  --should be 0
@TemplateID int = 0,   --should be 0
@TemplateName varchar(50) = '',
@TemplateVersion int = 0,
@ParameterList ntext = '<root></root>',
@ClearAll int = 0,
@Page int = 0,
@Version int = 0,
@UID int = 0,
@HostName varchar(50) = '',
@LanguageId int = 0
AS
if (@TemplateID = 0)
begin
declare @count int
select @count = count(dashboard_template_id) from dashboard_templates where
case when isnumeric(dashboard_template_name) = 1 then (dbo.fnDBTranslate(@LanguageId, dashboard_template_name, dashboard_template_name)) 
else (dashboard_template_name)
end  = 
case when isnumeric(@TemplateName) = 1 then (dbo.fnDBTranslate(@LanguageId, @TemplateName, @TemplateName)) 
else (@TemplateName)
end
and version = @templateversion
if (@count = 0)
begin
select 0 as dashboard_template_id
end
else
begin
 	 select @templateid = dashboard_template_id from dashboard_templates 
where 
case when isnumeric(dashboard_template_name) = 1 then (dbo.fnDBTranslate(@LanguageId, dashboard_template_name, dashboard_template_name)) 
else (dashboard_template_name)
end  = case when isnumeric(@TemplateName) = 1 then (dbo.fnDBTranslate(@LanguageId, @TemplateName, @TemplateName)) 
else (@TemplateName)
end
 and version = @templateversion
 	 select @templateId as dashboard_template_id
end
end
else
begin
 	 select @templateId as dashboard_template_id
end
if (@ReportID = 0)
begin
 	 EXECUTE @reportid = spDBR_Create_Ad_Hoc_Report_From_Web_Part @reportfromid, @templateid, @clearall, @parameterlist
end
else
begin
 	 EXECUTE spDBR_Prepare_Web_Part @reportid, @clearall, @parameterlist
end
 	 EXECUTE spDBR_Get_Report_XSL @reportid
if (@version = 0)
begin
 	 set @version = 1
end
if (@Page = 0)
begin
 	 EXECUTE spDBR_Get_Report_XML @reportid, @version
end
else
begin
 	 EXECUTE spDBR_Get_Report_Page @reportid, @page
end
 	 EXECUTE spDBR_Get_Null_Params @reportid, @clearall
 	 EXECUTE spDBR_Get_XSL_Script_Node
 	 EXECUTE spDBR_Get_Web_Part_Path @UID, @HostName
/* 	 EXECUTE spDBR_Get_XSL_Parameters @reportid
*/
 	 EXECUTE spDBR_Update_Report_Statistics @reportid
