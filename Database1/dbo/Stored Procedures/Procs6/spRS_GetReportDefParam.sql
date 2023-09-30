-----------------------------------------------------------------
-- This stored procedure is used by the following applications:
-- ProficyRPTAdmin
-- ProficyRPTEngine
-- Edit the master document in VSS project: ProficyRPTAdmin
-----------------------------------------------------------------
CREATE PROCEDURE dbo.spRS_GetReportDefParam
@Report_Id int
AS
select RDP.RDP_Id, RP.RP_Name, RP.spName, RP.MultiSelect, RPG.Group_Name, RPT.RPT_Name, RDP.Value, RP.Is_Default
from report_definition_parameters RDP
left join Report_Type_Parameters RTP on RDP.RTP_Id = RTP.RTP_Id
Left Join Report_Parameters RP on RTP.RP_ID = RP.RP_Id
left Join Report_Parameter_Groups RPG on RPG.Group_Id = RP.RPG_Id
Left Join Report_Parameter_Types RPT on RP.RPT_Id = RPT.RPT_Id
where RDP.Report_Id = @Report_Id
Order By RP.RP_Name
