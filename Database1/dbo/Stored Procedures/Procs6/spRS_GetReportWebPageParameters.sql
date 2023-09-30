CREATE PROCEDURE dbo.spRS_GetReportWebPageParameters
@RWP_Id int
 AS
select RP.RP_Name, RP.Description, RP.Default_Value, RP.Is_Default, rwp.*
from report_webpage_Parameters RWP
left join report_parameters RP on  RWP.RP_Id = RP.RP_Id
where rwp_Id = @RWP_Id
