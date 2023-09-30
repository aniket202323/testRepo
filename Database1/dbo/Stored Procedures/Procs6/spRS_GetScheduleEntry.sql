CREATE PROCEDURE dbo.spRS_GetScheduleEntry
@Schedule_Id int
 AS
Declare @Owner varchar(50)
Declare @Report_Id int
Select @Report_Id = Report_Id
From Report_Schedule
Where Schedule_Id = @Schedule_Id
Exec spRS_GetReportParamValue 'Owner', @Report_Id, @Owner output
Select RS.*, File_Name, Report_Name, @Owner 'Owner', Class From Report_Schedule RS
  LEFT JOIN Report_Definitions RD on RS.Report_Id = RD.Report_Id
Where RS.Schedule_Id = @Schedule_Id
