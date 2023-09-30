CREATE PROCEDURE dbo.spRS_AdminGetAdvancedSchedule
@Schedule_Id int = 0,
@InTimeZone varchar(200) = ''
AS
Declare @Report_Id int
Select @Report_Id = Report_Id From Report_Schedule Where Schedule_Id = @Schedule_Id
Select RD.Priority, RS.Schedule_Id,RS.Computer_Name,RS.Daily,RS.Description,RS.Error_Code,RS.Error_String,RS.Interval,RS.Last_Result,Last_Run_Time=dbo.fnServer_CmnConvertFromDBTime(RS.Last_Run_Time,@InTimeZone),
 RS.Monthly,Next_Run_Time=dbo.fnServer_CmnConvertFromDBTime(RS.Next_Run_Time,@InTimeZone),RS.Process_Id,RS.Report_Id,RS.Run_Attempts,Start_date_Time=dbo.fnServer_CmnConvertFromDBTime(RS.Start_date_Time,@InTimezone),RS.Status From Report_Schedule RS
Join Report_Definitions RD on RS.Report_Id = RD.Report_Id
Where RS.Report_Id = @Report_Id
return
