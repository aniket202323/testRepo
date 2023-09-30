CREATE PROCEDURE [dbo].[spRS_RptSchedule] 
AS
Create Table #TempSched(
  Report_Name varchar(50),
  Last_Run datetime, 
  interval int,
  Last_Result int,
  Last_Description varchar(25) null,
  Error_Code int,
  Error_Description varchar(25) null,
  Status int,
  Status_Description varchar(25) null
)
insert into #TempSched
  select r.report_Name, s.Last_run_Time, s.interval, s.last_result, null, s.error_code, null, s.status, null
  from report_schedule s
  join report_definitions r on r.report_id = s.report_id
update #TempSched
  Set last_Description = (Select Code_Desc from return_error_codes where group_Id = 3 and code_value = last_result),
      Error_Description = (Select Code_Desc from return_error_codes where group_Id = 5 and code_value = Error_Code),
      Status_Description = (Select Code_Desc from return_error_codes where group_Id = 1 and code_value = Status)
select Report_Name, Last_Run 'Last_Run_Time', Last_Description 'Last_Run', Error_Description, Status_Description from #TempSched
Drop Table #TempSched
