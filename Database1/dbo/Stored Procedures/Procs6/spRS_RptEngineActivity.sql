CREATE PROCEDURE dbo.spRS_RptEngineActivity
@StartTime DateTime = Null,
@EndTime DateTime = Null
 AS
If @StartTime Is Null
  Begin
    Select @StartTime = dateadd(day,-1,getdate())
    Select @EndTime = getdate()
  End
Create table #EngineActivity (
  EngineName varchar(50),
  ServiceName varchar(25),
  ReportRuns int NULL,
  Failures int NULL,
  Starts int NULL,
  PercentFail float NULL
)
Create table #EngineStarts (
  EngineName varchar(50),
  ServiceName varchar(25),
  Starts int NULL
)
--Engine Query For Activity
insert into #EngineActivity (EngineName, ServiceName,ReportRuns, Failures)
  select e.engine_name, e.service_name, ReportRuns = count(r.Start_Time), Failures = sum(Case when r.error_id > 0 then 1 else 0 end)
    from report_runs r
    join report_engines e on e.engine_id = r.engine_id 
    where r.start_time between @StartTime and @EndTime
    group by e.engine_name, e.service_name
--Engine Starts 
insert into #EngineStarts
  select e.engine_name, e.service_name, Starts = count(a.Time)
    from report_engine_activity a
    join report_engines e on e.engine_id = a.engine_id 
    where a.time between @StartTime and @EndTime and message like '%startup%'
    group by e.engine_name, e.service_name
Update #EngineActivity
  Set Starts = (Select #EngineStarts.Starts From #EngineStarts Where #EngineActivity.ServiceName =  #EngineStarts.ServiceName and #EngineActivity.EngineName =  #EngineStarts.EngineName), 
      PercentFail = convert(float, Failures) / convert(float, ReportRuns) * 100.0
Select EngineName + '-' + ServiceName 'Engine', ReportRuns 'Report_Runs', Failures, Starts, PercentFail 'Percent_Fail'
from #EngineActivity
  Order By PercentFail DESC
drop table #EngineStarts
drop table #EngineActivity
