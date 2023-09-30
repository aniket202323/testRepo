Create Procedure dbo.spDBR_Prepare_Web_Part
@reportid int,
@clearall int,
@overrides text
AS
 	 declare @templateid int
 	 set @templateid = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @reportid)
 	 
 	 if (@clearall = 1)
 	 begin
 	  	 Execute spDBR_Clear_Report_Parameter_Values @reportid
 	 end
 	 
 	 execute spDBR_Override_Parameters @reportid, @templateid, @overrides
 	 execute spDBR_Get_Report_Display_Vars @reportid
 	 
-- 	 select @reportid as dashboard_report_id
-- 	 select ParameterID, ParameterName, ParameterValue from #ParamOverrides a, #ParamValues b where a.XMLID = b.XMLID
