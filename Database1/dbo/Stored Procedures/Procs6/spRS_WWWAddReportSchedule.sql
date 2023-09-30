CREATE PROCEDURE [dbo].[spRS_WWWAddReportSchedule]
@Report_Id int,
@Class int
 AS
Declare @Schedule_Id int
Declare @Time datetime
Select @Time = GetDate()
Exec spRS_AddReport_Schedule @Report_Id, @Time, 1440, @Time, @Time, 0, 0, @Class, @Schedule_Id output
Select @Schedule_Id
