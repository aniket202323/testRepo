-- This procedure will return all of the available parameters or only the parameters for a particular report type
--
CREATE PROCEDURE dbo.spXLAWbWiz_GetReportTypeParameters
 	 @Report_Type_Id int = NULL
AS
If @Report_Type_Id Is NULL
  BEGIN
      SELECT RP.*, RPT.RPT_Name, 0 'Optional'
        FROM Report_Parameters RP
        LEFT JOIN Report_Parameter_Types RPT on RP.RPT_Id = RPT.RPT_Id
    ORDER BY RP.RP_Name
  END
Else
  BEGIN
      -- Output needs to be in this order for COA (per Alex)
      -- RTP_Id, Report_Type_Id, RP_Id, Optional, Default_Value, RP_Name, Description, MultiSelect, spName, RPT_Name
      SELECT RTP.RTP_Id, RTP.Report_Type_Id, RTP.RP_Id, RTP.Optional, RTP.Default_Value, RP.RP_Name, RP.Description, RP.MultiSelect, RP.spName, RPT.RPT_Name
        FROM Report_Type_Parameters RTP
        LEFT JOIN Report_Parameters RP On RP.RP_Id = RTP.RP_Id
        LEFT JOIN Report_Parameter_Types RPT on RP.RPT_Id = RPT.RPT_Id
       WHERE RTP.Report_Type_Id = @Report_Type_Id
    ORDER BY RP.RP_Name
  END
--EndIf
