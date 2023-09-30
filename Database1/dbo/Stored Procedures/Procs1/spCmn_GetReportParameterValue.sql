-------------------------------------------------------------------------------
-- Desc:
-- This stored procedure returns the parameter value for a given parameter in a
-- report definition
--
-- Edit History:
-- RP 21-Nov-2002 MSI Development
--
-- Arguments:
-- spCmn_GetReportParameterValue 
-- ReportName  	  	 >>>> Report_Name from Report_Definition_Parameters table
-- ParameterName  	 >>>> RP_Name from Report_Parameters
-- DefaultValue 	 >>>> Value to use if the parameter is Null or not present 
-- 	 OutputValue 	  	 >>>> Parameter value
--
-- Sample Exec statement:
/*
DECLARE 	 @RptParameterValue nVarChar(4000)
EXEC 	 spCmn_GetReportParameterValue
 	  	 NULL, 	 intRptOwnerId, 1, 	 @RptParameterValue OUTPUT
SELECT @RptParameterValue
*/
-------------------------------------------------------------------------------
CREATE PROCEDURE  dbo.spCmn_GetReportParameterValue
 	 @PrmRptName 	  	  	  	 nVarChar(255) 	 = Null,
 	 @PrmParameterName 	  	 nVarChar(255) 	  	  	 ,
 	 @PrmDefaultValue 	  	 nVarChar(4000) = Null,
 	 @PrmOutputValue 	  	 nVarChar(4000) 	 OUTPUT
AS
DECLARE
@ParameterValue nVarChar(4000)
IF 	 Len(@PrmRptName) > 0
BEGIN
 	 SELECT 	 @ParameterValue = rdp.Value
 	  	 FROM  	 Report_Definition_Parameters  	 rdp
 	  	 JOIN  	 Report_Definitions  	  	  	  	 rd  	 ON rd.Report_id = rdp.Report_id
 	  	 JOIN 	 Report_Type_Parameters  	  	  	 rtp  	 ON rtp.rtp_id = rdp.rtp_id
 	  	 JOIN  	 Report_Parameters  	  	  	  	 rp  	 ON rp.rp_id = rtp.rp_id
 	  	 --
 	  	 WHERE rd.Report_Name 	 = @PrmRptName
 	  	 AND 	 rp.RP_Name  	  	 = @PrmParameterName
END
--
SELECT 	 @PrmOutputValue = Coalesce(@ParameterValue, @PrmDefaultValue)
 	 
RETURN
SET QUOTED_IDENTIFIER OFF 
