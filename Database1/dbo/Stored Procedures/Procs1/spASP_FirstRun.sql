CREATE PROCEDURE [dbo].[spASP_FirstRun]
@ReportId int,
@RunId int = NULL
AS
Declare @RunTime varchar(255)
Select @RunTime = 'Report Generation Occured At: ' + Convert(Varchar(35), GetDate(), 120)
-- Update A Value In The Definition
Exec spRS_AddReportDefParam @ReportId, 'Options', @RunTime
Select RP.RP_Name, RDP.Value
from report_definition_parameters RDP
Left join Report_Type_Parameters RTP on RDP.RTP_Id = RTP.RTP_Id
Left Join Report_Parameters RP on RTP.RP_ID = RP.RP_Id
Left Join Report_Parameter_Groups RPG on RPG.Group_Id = RP.RPG_Id
Left Join Report_Parameter_Types RPT on RP.RPT_Id = RPT.RPT_Id
Where RDP.Report_Id = @ReportId
Order By RP.RP_Name
