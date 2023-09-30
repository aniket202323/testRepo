-- spXLAWbWiz_AllReportParameters returns all available parameters excluding system parameter (Is_Default = 1)
--
CREATE PROCEDURE dbo.spXLAWbWiz_AllReportParameters
AS
  -- Optional = 0 means do not include this parameter in the "Option" webpage; 1 means yes include it
  -- We'll leave it at 0 (no) for now. User must use Web Administrator Module to configure it otherwise
  SELECT RP.*, RPT.RPT_Name, [Optional] = 0
    FROM Report_Parameters RP
    LEFT JOIN Report_Parameter_Types RPT on RP.RPT_Id = RPT.RPT_Id
   WHERE RP.Is_Default = 0
ORDER BY RP.RP_Name
