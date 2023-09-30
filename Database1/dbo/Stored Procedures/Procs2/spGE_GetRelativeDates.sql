/*
spGE_GetRelativeDates 105
select * from sheets
execute spGE_GetRelativeDates 'Central Standard Time'
execute spGE_GetRelativeDates 376
--select * from TimeZoneTranslations
*/
Create Procedure dbo.spGE_GetRelativeDates
 	 @PUId Int
  AS
DECLARE @PromptData Table (RRD_Id Int,PromptId Int,StartTime DateTime,EndTime DateTime)
DECLARE @TempTime 	 DateTime,
 	  	 @UTCNow 	  	 DateTime,
 	  	 @Endtime 	 datetime,
 	  	 @DbNow 	  	 DateTime,
 	  	 @DbTZ 	  	 nvarchar(200),
 	  	 @LocalTimeZoneName nvarchar(200),
 	  	 @Deptid 	  	 Int
 	 
SELECT @Deptid = dbo.fnServer_GetDepartment(@PUId)
SELECT @LocalTimeZoneName = dbo.fnServer_GetTimeZone(@PUId)
SELECT @DbTZ=value from site_parameters where parm_id=192
IF @LocalTimeZoneName Is Null
 	 SELECT @LocalTimeZoneName = @DbTZ
SELECT @UTCNow = Getutcdate()
SELECT @DbNow = dbo.fnServer_CmnGetdate(@UTCNow)
SELECT @Endtime =  dbo.fnServer_CmnConvertTime (@DbNow,@DbTZ,@LocalTimeZoneName)
Insert Into @PromptData(RRD_Id,PromptId) 	 Values (25,36297)
Insert Into @PromptData(RRD_Id,PromptId) 	 Values (26,36059)
Insert Into @PromptData(RRD_Id,PromptId) 	 Values (27,36058)
Insert Into @PromptData(RRD_Id,PromptId) 	 Values (28,36296)
Insert Into @PromptData(RRD_Id,PromptId) 	 Values (29,36295)
Insert Into @PromptData(RRD_Id,PromptId) 	 Values (30,36158)
Insert Into @PromptData(RRD_Id,PromptId) 	 Values (31,36294)
Select @TempTime = dbo.fnCMN_CalculateDayStartTime(@PUId)
UPDATE @PromptData SET StartTime = @TempTime,EndTime = @Endtime where RRD_Id = 30
--31          Yesterday
UPDATE @PromptData SET StartTime = DateAdd(Day,-1,@TempTime),EndTime  = @TempTime where RRD_Id = 31
--28          Last 3 Days
UPDATE @PromptData SET StartTime = DateAdd(Day,-3,@TempTime),EndTime  = @TempTime where RRD_Id = 28
--26          Last 7 Days
UPDATE @PromptData SET StartTime = DateAdd(Day,-7,@TempTime),EndTime  = @TempTime where RRD_Id = 26
--27          Last 30 Days
UPDATE @PromptData SET StartTime = DateAdd(Day,-30,@TempTime),EndTime  = @TempTime where RRD_Id = 27
--29          This Month
UPDATE @PromptData SET StartTime = DateAdd(Day,-Datepart(Day,@TempTime)+ 1,@TempTime),EndTime  = @Endtime where RRD_Id = 29
--25          Last Month
UPDATE @PromptData SET StartTime = DateAdd(Month,-1,DateAdd(Day,-Datepart(Day,@TempTime)+ 1,@TempTime)),EndTime  = DateAdd(Day,-Datepart(Day,@TempTime)+ 1,@TempTime) where RRD_Id = 25
Select rd.RRD_Id,Default_Prompt_Desc,PromptId = coalesce(PromptId,0),StartTime,EndTime
 From report_relative_dates rd
 Join @PromptData pd on pd.RRD_Id = rd.RRD_Id
 Order by Default_Prompt_Desc
