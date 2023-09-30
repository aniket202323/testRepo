Create Procedure dbo.spDBR_Export_Template_XSL
@template_id int
AS
 	 select dashboard_template_xsl from dashboard_templates  where dashboard_template_id =@template_id for xml raw
