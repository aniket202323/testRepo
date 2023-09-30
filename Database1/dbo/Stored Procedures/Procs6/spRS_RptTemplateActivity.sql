CREATE PROCEDURE [dbo].[spRS_RptTemplateActivity] 
@StartTime datetime = null,
@EndTime datetime = null
AS
If @StartTime Is Null
  Begin
    Select @EndTime = GetDate()
    Select @StartTime = DateAdd(day, -1, @EndTime)
  End
--Template Run Query
select rt.Description, 
       Report_Runs = count(r.Start_Time), 
       Failures = sum(Case when r.error_id > 0 then 1 else 0 end),
       Max_Time = max(DateDiff(second, r.Start_Time, r.End_Time)), 
       Min_Time = min(DateDiff(second, r.Start_Time, r.End_Time)), 
       Avg_Time = Avg(DateDiff(second, r.Start_Time, r.End_Time)),
       Percent_CPU =  sum(convert(float, DateDiff(second, r.Start_Time, r.End_Time)) / convert(float, DateDiff(second, @StartTime, @EndTime)) * 100.0)
  from report_runs r
  join report_definitions rd on rd.report_id = r.report_id
  join report_types rt on rt.report_type_id = rd.report_type_id
  where r.start_time between @StartTime and @EndTime and r.End_Time is not null
  group by rt.Description
  order by Failures DESC
