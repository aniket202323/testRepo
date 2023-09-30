CREATE PROCEDURE dbo.spXLAWbWiz_GetReportWebPageParameters
 	 @RWP_Id Int
AS
  -- Optional = 0 means do not include this parameter in the "Option" webpage; 1 means yes include it
  -- PrfWbWiz will retrieve 0 (no) for now and send back 0 when its time to update. 
  -- User must use Web Administrator Module to configure it otherwise
SELECT RP.RP_Name, RP.Description, RP.Default_Value, RP.Is_Default, RWP.*, [Optional] = 0
  FROM Report_Webpage_Parameters RWP
  LEFT JOIN Report_parameters RP ON  RWP.RP_Id = RP.RP_Id
 WHERE RWP_Id = @RWP_Id
