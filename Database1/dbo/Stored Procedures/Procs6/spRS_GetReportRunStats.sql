CREATE PROCEDURE dbo.spRS_GetReportRunStats
@Report_Id int
 AS
Declare @AvgRunTime int
Declare @MinRunTime int
Declare @MaxRunTime int
Declare @TotalRuns int
Declare @TotalTime int
Declare @ReportTimeOut varchar(255)
Declare @ReportTypeId int
-- Get the report type id
Select @ReportTypeId = Report_Type_Id
from Report_Definitions
Where Report_Id = @Report_Id
Execute sprs_GetReportParamValue 'MinRunTime', @Report_Id, @MinRunTime output
If @MinRunTime Is Null
  Select @MinRunTime = 0
Execute sprs_GetReportParamValue 'MaxRunTime', @Report_Id, @MaxRunTime output
If @MaxRunTime Is Null
  Select @MaxRunTime = 0
Execute sprs_GetReportParamValue 'TotalRuns', @Report_Id, @TotalRuns output
If @TotalRuns Is Null
  Select @TotalRuns = 0
Execute sprs_GetReportParamValue 'TotalTime', @Report_Id, @TotalTime output
If @TotalTime Is Null
  Select @TotalTime = 0
Execute sprs_GetReportParamValue 'ReportTimeout', @Report_Id, @ReportTimeout output
If @ReportTimeout Is Null
  Select @ReportTimeout = 5
If (@TotalTime = 0) or (@TotalRuns = 0)
  Select @AvgRunTime = 0
Else
  Select @AvgRunTime = @TotalTime / @TotalRuns
-- if the total runs = 0 then call sprs_GetReportTypeRunData
If (@TotalRuns = 0)
  exec spRS_GetReportTypeRunData @ReportTypeId, @MinRunTime output, @MaxRunTime output, @AvgRunTime output
Select @AvgRunTime AvgRunTime, @MinRunTime MinRunTime, @MaxRunTime MaxRunTime, @TotalRuns TotalRuns, @TotalTime TotalTime, @ReportTimeout ReportTimeout
