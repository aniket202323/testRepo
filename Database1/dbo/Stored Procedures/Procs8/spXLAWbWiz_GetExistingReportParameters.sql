--spXLAWbWiz_GetExistingReportParameters() retrieves parameters for a given Report_Type_Id; system parameters
--are excluded. System parameters are Report_Parameters.RP_Id whose Report_Paramaeters.Is_Default = 1
--mt/11-25-2002
--
CREATE PROCEDURE dbo.spXLAWbWiz_GetExistingReportParameters
 	 @Report_Type_Id Int
AS
  SELECT RTP.*, RP.RP_Name, RP.Description
    FROM Report_Type_Parameters RTP
    LEFT JOIN Report_Parameters RP ON RP.RP_Id = RTP.RP_Id 
   WHERE RTP.Report_Type_Id = @Report_Type_Id AND RP.Is_Default = 0
ORDER BY RP.RP_Name
