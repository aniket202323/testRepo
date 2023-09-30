Create Procedure dbo.spDBR_Create_Ad_Hoc_Report_From_Web_Part
@reportfromid int,
@templateid int,
@clearall int,
@overrides ntext
AS
 	 declare @reportid int
 	 if (@reportfromid = 0)
 	 begin
 	  	 EXECUTE @reportid = spDBR_Create_Ad_Hoc_Report_From_Defaults @templateid
 	 end
 	 else
 	 begin
 	  	 Execute @reportid = spDBR_Create_Ad_Hoc_Report @reportfromid, @templateid
 	 end
-- 	 set @reportid = (select reportid from ##Report_ID)
 	 
 	 if (@clearall = 1)
 	 begin
 	  	 Execute spDBR_Clear_Report_Parameter_Values @reportid
 	 end
 	 
 	 execute spDBR_Override_Parameters @reportid, @templateid, @overrides
 	 execute spDBR_Get_Report_Display_Vars @reportid
 	 
-- 	 select @reportid as dashboard_report_id
-- 	 select ParameterID, ParameterName, ParameterValue from #ParamOverrides a, #ParamValues b where a.XMLID = b.XMLID
