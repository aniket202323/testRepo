CREATE PROCEDURE dbo.spRS_RptReportHitCount
@StartTime DateTime = Null,
@EndTime DateTime = Null
AS
If @StartTime Is Null
  Begin
    Select @StartTime = dateadd(day,-1,getdate())
    Select @EndTime = getdate()
  End
/*
Select rd.Report_Name, Count(*) 'Hits' From Report_Hits rh
Join Report_Definitions rd on rd.Report_Id = rh.Report_Id
where hittime > @StartTime
Group by rh.report_id,  rd.Report_Name
*/
Create table #t(Report_Type_Id int, report_name varchar(50), hits int)
Insert into #t(Report_Type_Id, Report_Name, hits)
  Select rd.report_type_id, rd.Report_Name, Count(*)
  From Report_Hits rh
  Join Report_Definitions rd on rd.Report_Id = rh.Report_Id
  where hittime > @StartTime
  and rd.Class in (2,3)
  Group by rd.report_type_id, rh.report_id,  rd.Report_Name
select Report_Name, 
       SubString(rt.Template_Path, charindex('s/', rt.Template_Path) + 2, 40) 'Template_Name', 
       Hits
from #t
join report_types rt on rt.Report_Type_Id = #t.Report_Type_Id
drop table #t
