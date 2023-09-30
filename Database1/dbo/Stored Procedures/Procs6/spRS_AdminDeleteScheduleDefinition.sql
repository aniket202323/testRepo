CREATE PROCEDURE dbo.spRS_AdminDeleteScheduleDefinition
@Report_Id int 
AS
Delete From Report_Que Where Schedule_Id in (Select Schedule_Id From Report_Schedule Where Report_Id = @Report_Id)
Delete From Report_Schedule Where Report_Id = @Report_Id
