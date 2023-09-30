Create Procedure dbo.spDBR_Get_Report_XSL
@ReportID int
AS
 	 declare @TemplateID int
 	 set @TemplateID = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @reportid)
 	 declare @dashboard_template_xsl_filename varchar(100)
 	 declare @proc varchar(100)
 	 declare @type int
 	 set @dashboard_template_xsl_filename = (select dashboard_Template_xsl_filename from dashboard_templates where dashboard_template_id = @TemplateID)
 	 set @proc = (select dashboard_Template_procedure from dashboard_templates where dashboard_template_id = @TemplateID)
 	 set @type = (select type from dashboard_templates where dashboard_template_id = @TemplateID)
 	 IF (@dashboard_template_xsl_filename = 'None')
 	 begin
 	  	 select XSL as dashboard_template_xsl,XSL_Filename as dashboard_template_xsl_filename, @proc as dashboard_template_procedure, @type as type  from dashboard_default_xsl where xsl_id=3 
 	 end
 	 else
 	 begin
 	  	 select dashboard_template_xsl, dashboard_template_xsl_filename, dashboard_template_procedure, type from dashboard_templates where dashboard_template_id = @templateid
 	 end
