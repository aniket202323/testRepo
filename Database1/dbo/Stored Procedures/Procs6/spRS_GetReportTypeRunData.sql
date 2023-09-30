CREATE PROCEDURE dbo.spRS_GetReportTypeRunData
@Report_Type_Id int,
@MinRunTime int output,
@MaxRunTime int output,
@AvgRunTime int output
 AS
--Declare @MinRunTime int  --RP_Id 31
--Declare @MaxRunTime int  --RP_Id 32
Declare @TotalRuns int   --RP_Id 33
Declare @TotalTime int   --RP_Id 34
--Declare @AvgRunTime int
-- Get the Min Run Time from all the min run times
select @MinRunTime = min(convert(int, value))
from report_definition_Parameters
where report_Id in
  (
    Select Report_Id
    From Report_Definitions
    Where Report_Type_Id = @Report_Type_Id
  )
and RTP_Id in
  (
    Select RTP_Id
    From report_type_parameters --this will give the RTP_Id
    Where report_type_Id = @Report_Type_Id
    and Rp_Id = 31
  )
-- Get the max run time from all the maximums
select @MaxRunTime = max(convert(int, value))
from report_definition_Parameters
where report_Id in
  (
    Select Report_Id
    From Report_Definitions
    Where Report_Type_Id = @Report_Type_Id
  )
and RTP_Id in
  (
    Select RTP_Id
    From report_type_parameters --this will give the RTP_Id
    Where report_type_Id = @Report_Type_Id
    and Rp_Id = 32
  )
-- Get the total number of runs for all definitions
select @TotalRuns = sum(convert(int,value))
from report_definition_Parameters
where report_Id in
  (
    Select Report_Id
    From Report_Definitions
    Where Report_Type_Id = @Report_Type_Id
  )
and RTP_Id in
  (
    Select RTP_Id
    From report_type_parameters --this will give the RTP_Id
    Where report_type_Id = @Report_Type_Id
    and Rp_Id = 33
  )
-- Get the Total Run Time for all definitions
select @TotalTime = sum(convert(int,value))
from report_definition_Parameters
where report_Id in
  (
    Select Report_Id
    From Report_Definitions
    Where Report_Type_Id = @Report_Type_Id
  )
and RTP_Id in
  (
    Select RTP_Id
    From report_type_parameters --this will give the RTP_Id
    Where report_type_Id = @Report_Type_Id
    and Rp_Id = 34
  )
If @TotalRuns > 0
  Select @AvgRunTime = @TotalTime / @TotalRuns
Else
  Select @AvgRunTime = 0
