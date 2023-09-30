--
/*  
 execute spBF_GetLineOEEKPIData
 @LineList = '1',
 @StartTime = '09/11/2016',
 @EndTime = '09/12/2016',
 @TimeSelection = 0,
 @FilterNonProductiveTime = 1,
 @InTimeZone = null,
 @SortOrder = 3,
 @AscDesc = 1,
 @ReturnType = 2,
 @pageSize = 9999,
 @pageNum = 1,
 @MaxResultsReturned = 1000,
 @FilterType = 0
*/
CREATE PROCEDURE [dbo].[spBF_GetLineOEEKPIData_Bak_177]
--@LineList                nvarchar(max), 	  	  	  	 -- Required (Null returns all Lines)
@UnitList 	  	  	  	 nvarchar(max),
@StartTime               datetime = NULL, 	  	  	 -- Used When @TimeSelection = 0 (user Defined time)
@EndTime                 datetime = NULL, 	  	  	 -- Used When @TimeSelection = 0 (user Defined time)
@TimeSelection 	  	  	  Int = 0, 	  	  	  	  	 -- 0 - Use Times Passed In, 1 - Current Day,2 - Previous Day,3 - Current Week,4 - Previous Week
@FilterNonProductiveTime int = 0, 	  	  	  	  	 -- 1 = remove NPT from results
@InTimeZone 	              nVarChar(200) = null, 	  	 -- timeZone to return data in (defaults to department if not supplied)
@SortOrder 	  	  	  	  Int = 1, 	  	  	  	  	 --  PercentOEE(!= 1,2,3,4),1 - PerformanceRate,2 - QualityRate,3 - AvailableRate,4 Unit Description
@AscDesc 	  	  	  	  Int = 0, 	  	  	  	  	 -- 0 - Ascending
@ReturnType 	  	  	  	  Int = 0, 	  	  	  	  	 -- 0 - Return all results, 1 -  Return Results For EA (limited results), 2 -  Return limited results For Children (requires 1 line Id),3 - return clockon data
@pageSize 	  	  	  	  	 Int = 4, 	  	  	  	 -- # Results returned
@pageNum 	  	  	  	  	 Int = 1, 	  	  	  	 -- Offest fro results
@MaxResultsReturned 	  	  	 Int = 10, 	  	  	  	 -- Maximum rows returned used for sort (@pageSize should be > this number)
@FilterType 	  	  	  	  	 Int = 0,                 -- 0 - no filter,1 clocked on,2 Clocked Off,3 Machine Running,4 Machine Down
@Summarize                  Int = 0 	  	  	  	  	  	 --if 1 willgive summary of all lines
,@TotalRowcount Int OUTPUT
AS
/* ##### spBF_GetLineOEEKPIData #####
Description 	 : Returns data for the donuts shown in Supervisory screen(Summary & line level
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	 UserStory/Defect No 	  	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 Added logic to fetch NPT, DowntimeA, DowntimeP, DowntimeQ, Downtime PL and toggle calculation based on OEE calculation type (Classic or Time Based)
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	 Passed actual filter for NPT
2018-06-08 	  	  	 Prasad 	  	  	  	 7.0 SP4 	  	  	  	  	  	  	 Added MachineCount in resultset
2018-06-20 	  	  	 Prasad 	  	  	  	 7.0 SP4 DE77740 	  	  	  	  	 Removed cap for PerformanceRate and PercentOEE
*/
set nocount on
Declare @low Int = 50
Declare @Moderate Int = 85
Declare @Good Int = 60
DECLARE @startRow 	 Int
DECLARE @endRow 	  	 Int
DECLARE @NewPageNum INt
SET @pageNum = coalesce(@pageNum,1)
SET @pageSize = coalesce(@pageSize,20)
SET @NewPageNum = @NewPageNum -1
SET @startRow = coalesce(@NewPageNum * @pageSize,0) + 1
SET @endRow = @startRow + @pageSize - 1
SET @TimeSelection = Coalesce(@TimeSelection,0)
SET @FilterNonProductiveTime = Coalesce(@FilterNonProductiveTime,0)
SET @SortOrder = Coalesce(@SortOrder,1)
SET @AscDesc = Coalesce(@AscDesc,0)
SET @ReturnType = Coalesce(@ReturnType,0)
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
IF @ReturnType Not in (2,3) 
 	 SET @FilterType = 0 
DECLARE
 	  	 @LineRows 	  	 int,
 	  	 @Row 	  	  	 int,
 	  	 @LineId 	  	  	 int,
 	  	 @OEECalcType 	 Int,
 	  	 @CapRates 	  	 tinyint
DECLARE @Lines TABLE  ( RowID int IDENTITY, 	 LineId int NULL,LineDesc nvarchar(50),OEEMode Int)
DECLARE @FilteredLines TABLE  ( RowID int IDENTITY, 	 LineId int NULL,LineDesc nvarchar(50),OEEMode Int)
DECLARE @PagedLines TABLE  ( RowID int IDENTITY, 	 LineId int NULL,LineDesc nvarchar(50),OEEMode Int)
--DECLARE @UnitList 	 nvarchar(max)
DECLARE @Linesummary TABLE
(
 	 LineDesc nvarchar(50) null,
 	 UnitId 	 Int null,
 	 UnitDesc nvarchar(50) null,
 	 UnitOrder 	 Int Null,
 	 ProductionAmount Float null,
 	 IdealProductionAmount Float null,
 	 ActualSpeed Float null,
 	 IdealSpeed Float null,
 	 PerformanceRate Float null,
 	 WasteAmount Float null,
 	 QualityRate Float null,
 	 PerformanceTime Float DEFAULT 0,
 	 RunTime Float DEFAULT 0,
 	 LoadingTime Float DEFAULT 0,
 	 AvailableRate Float null,
 	 PercentOEE  Float DEFAULT 0,
 	 StartTime 	 DateTime,
 	 EndTime 	  	 DateTime,
 	 LineStatus 	 Int
 	 ,NPT float default 0
 	 ,DowntimeA float default 0
 	 ,DowntimeP float default 0
 	 ,DowntimeQ float default 0
 	 ,DowntimePL float default 0
 	 ,OEEMode int default 0
 	 ,MachineCount int default 0
)
DECLARE @Units Table (PUId 	 Int,OEEMode Int,UnitStatus Int)
DECLARE @FilteredUnits Table (PUId 	 Int)
SELECT 	 @CapRates = dbo.fnCMN_OEERateIsCapped()
DECLARE  @Summary TABLE 
(
Line nvarchar(100),
UnitId Int,
UnitDesc  nvarchar(100),
UnitOrder Int,
ProductionAmount Float, 
IdealProductionAmount Float, 
ActualSpeed  Float,
IdealSpeed Float,
PerformanceRate Float,
WasteAmount Float, 
QualityRate  Float,
PerformanceTime Float,
RunTime Float,
LoadingTime Float,
AvailableRate  Float,        
PercentOEE Float
,NPT float default 0
 	 ,DowntimeA float default 0
 	 ,DowntimeP float default 0
 	 ,DowntimeQ float default 0
 	 ,DowntimePL float default 0
 	 ,OEEMode int default 0
 	 ,MachineCount int default 0
 	 )
Declare @LineList nvarchar(max)
SET @LineList = NULL
  	  
 	  Insert into @Units(PUId)
 	  Select col1 from dbo.fn_SplitString(@UnitList,',')
  	  UPDATE @Units SET OEEMode = 1;
  	  update a
   	   Set OEEMode = coalesce(b.Value,1) 
   	   From @Units a
   	   Join dbo.Table_Fields_Values  b on b.KeyId = a.PUId   AND b.Table_Field_Id = -91 AND B.TableId = 43
 	 update a
  	  Set UnitStatus = coalesce(b.TEDet_Id,0) 
  	  From @Units a
  	  Left Join Timed_Event_Details  b on b.PU_Id = a.PUId   AND b.End_Time is null
 	 update @Units  	  Set UnitStatus = 1 where UnitStatus > 0
 	 Insert Into @Linesummary(LineDesc,UnitId,UnitDesc,UnitOrder,ProductionAmount,
 	  	  	 IdealProductionAmount,ActualSpeed,IdealSpeed,PerformanceRate,WasteAmount,
 	  	  	 QualityRate,PerformanceTime,RunTime,LoadingTime,AvailableRate,
 	  	  	 PercentOEE,NPT,DownTimeA,DownTimeP,DowntimeQ,DowntimePL,OEEMode,MachineCount)
 	  	  	  	 
 	  	 EXECUTE spBF_OEEGetData_MasterUnits @UnitList, @StartTime,@EndTime,@FilterNonProductiveTime,@InTimeZone,@ReturnType
 	  	 UPDATE @Linesummary SET  StartTime = @StartTime,EndTime = @EndTime
 	  	 DECLARE @UnitCount Int,@DownUnitCount Int
 	  	 
 	 --<When a line has units with different OEEModes we need to sum up all the values for those units.>
 	 Select * into #tmplineSummary from @Linesummary
 	 Delete from @Linesummary
 	 Insert Into @Linesummary(LineDesc,UnitId,UnitDesc,UnitOrder,ProductionAmount,
 	  	  	  	 IdealProductionAmount,ActualSpeed,IdealSpeed,PerformanceRate,WasteAmount,
 	  	  	  	 QualityRate,PerformanceTime,RunTime,LoadingTime,AvailableRate,
 	  	  	  	 PercentOEE,NPT,DownTimeA,DownTimeP,DowntimeQ,DowntimePL,OEEMode,MachineCount)
 	 Select LineDesc,UnitId,UnitDesc,UnitOrder,Sum(ProductionAmount),
 	  	  	  	 Sum(IdealProductionAmount),sum(ActualSpeed),sum(IdealSpeed),sum(PerformanceRate),sum(WasteAmount),sum(QualityRate),
 	  	  	  	 sum(PerformanceTime),sum(RunTime),sum(LoadingTime),sum(AvailableRate),sum(PercentOEE),sum(NPT),sum(DownTimeA),sum(DownTimeP),
 	  	  	  	 sum(DowntimeQ),sum(DowntimePL),1,sum(MachineCount) from #tmplineSummary group by LineDesc,UnitId,UnitDesc,UnitOrder
 	 Drop table #tmplineSummary
  	 
 	 
  	  UPDATE A
 	 SET
 	  	 OEEMode = P.OEEMode
 	 From @Linesummary A 
 	 JOIN @PagedLines P on P.LineId = A.UnitId
 	 --<TIME BASED CALCULATION>--
 	 UPDATE A
 	 SET
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END *100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END*100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100
 	 From @Linesummary A 
 	 --WHERE OEEMode  = 4
 	 UPDATE @Linesummary SET PerformanceRate = CASE WHEN PerformanceRate > 100 AND @CapRates = 1  THEN 100 ELSE PerformanceRate END
 	 UPDATE @Linesummary SET PercentOEE = ( (PerformanceRate/100)*(QualityRate/100)*(AvailableRate/100)) *100
 	 --</TIME BASED CALCULATION>--
 	 
 	 
IF @ReturnType = 0
BEGIN
 	 IF @Summarize = 0 
       BEGIN
 	 SELECT 	 Line = LineDesc, UnitID , UnitDesc, UnitOrder , s.ProductionAmount, s.IdealProductionAmount,
 	  	 s.ActualSpeed, s.IdealSpeed, 
 	  	 PerformanceRate = 
 	  	 CASE WHEN s.PerformanceRate > 100 AND @CapRates = 1 THEN 100
 	  	  	 ELSE s.PerformanceRate END
 	  	  	 --s.PerformanceRate
 	  	  	 , 
 	  	 s.WasteAmount, 
 	  	 QualityRate = CASE WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100 
 	  	  	  	  	  	 ELSE s.QualityRate END,
 	  	 s.PerformanceTime, s.RunTime, s.LoadingTime, 
 	  	 AvailableRate = CASE WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	 ELSE s.AvailableRate END, 
 	  	 PercentOEE = 
 	  	 CASE WHEN s.PercentOEE > 100 AND @CapRates = 1 AND @CapRates = 1 THEN 100 
 	  	  	  	  	 ELSE s.PercentOEE END
 	  	  	  	  	 --s.PercentOEE
 	  	  	  	  	 ,OEEMode,MachineCount
 	 FROM @Linesummary s
 	 ORDER BY PercentOEE
 	  	  	    OFFSET @pageSize *(@pageNum - 1) ROWS
 	  	   FETCH NEXT @pageSize ROWS ONLY; 
 	  	 END
    ELSE
         BEGIN
              INSERT INTO @Summary(Line,UnitId,UnitDesc, UnitOrder,ProductionAmount, 
                                         IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate, WasteAmount, 
                                         QualityRate, PerformanceTime, RunTime,  LoadingTime,   AvailableRate ,        
                                          PercentOEE,NPT,DownTimeA,DownTimeP,DowntimeQ,DowntimePL,OEEMode,MachineCount)
              SELECT 'Dept', 1 , 'All', 1 , SUM(s.ProductionAmount), SUM(s.IdealProductionAmount),
              ActualSpeed = Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE sum(s.ProductionAmount)/Sum(s.RunTime) END,
 	  	  	 IdealSpeed = Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE Sum(s.IdealProductionAmount) / Sum(s.RunTime)END,
              dbo.fnGEPSPerformance(sum(ProductionAmount), sum(IdealProductionAmount), @CapRates), 
              sum(s.WasteAmount), 
               dbo.fnGEPSQuality(sum(ProductionAmount), sum(WasteAmount), @CapRates),
              sum(s.PerformanceTime), sum(s.RunTime), sum(s.LoadingTime), 
              Case WHEN sum(s.LoadingTime) = 0 THEN 0 Else Case WHEN((sum(s.RunTime) + SUM(PerformanceTime))/ sum(s.LoadingTime))*100 > 100 and @CapRates = 1 THEN
              100 ELSE ((sum(s.RunTime) + SUM(PerformanceTime))/ sum(s.LoadingTime))*100  END END, 
              0,SUM(NPT),SUM(DownTimeA),SUM(DownTimeP),SUM(DowntimeQ),SUM(DowntimePL),1,SUM(MachineCount)
       FROM @Linesummary s
 	    
 	     UPDATE A
 	  	 SET
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END *100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END*100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100
 	  	 From @Summary A 
 	  	 
       update @Summary set PercentOEE = ((PerformanceRate/100) * (AvailableRate/100) * (QualityRate/100)) * 100
       SELECT Line,UnitId,UnitDesc, UnitOrder,ProductionAmount, 
              IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate, WasteAmount, 
              QualityRate, PerformanceTime, RunTime,  LoadingTime,   AvailableRate ,        
              PercentOEE
 	  	  	     ,(select CASE WHEN Count(0)  = Count(case when OEEMode = 4 then 1 else NULL end) THEN 1 ELSE  0 END From @PagedLines) OEEMode
 	  	  	  	 ,MachineCount
 	  	  	    FROM @Summary
 	  	  	    ORDER BY  CASE WHEN @SortOrder = 4 THEN Line End,
 	  	  	  	  	 CASE WHEN @SortOrder = 1 THEN PerformanceRate 
 	  	  	  	  	   WHEN @SortOrder = 2 THEN QualityRate
 	  	  	  	  	   WHEN @SortOrder = 3 THEN AvailableRate
 	  	  	  	  	   ELSE PercentOEE  
 	  	  	  	 END DESC,Line Asc
 	  	  	    OFFSET @pageSize *(@pageNum - 1) ROWS
 	  	   FETCH NEXT @pageSize ROWS ONLY; 
 	  	 END
END
Select @TotalRowcount = Count(0) from @Linesummary
ReturnData:
IF @ReturnType = 3 
BEGIN
 	 DELETE FROM  @Linesummary WHERE  UnitDesc = 'All'
END
set rowcount @MaxResultsReturned
UPDATE @Linesummary
SET
 	 AvailableRate= Case when AvailableRate <0 Then 0 Else AvailableRate End
 	 ,PerformanceRate = Case when PerformanceRate < 0 Then 0 Else PerformanceRate End
 	 ,QualityRate= Case when QualityRate <0 then 0 else QualityRate end
UPDATE @Summary
SET
 	 AvailableRate= Case when AvailableRate <0 Then 0 Else AvailableRate End
 	 ,PerformanceRate = Case when PerformanceRate < 0 Then 0 Else PerformanceRate End
 	 ,QualityRate= Case when QualityRate <0 then 0 else QualityRate end
update @Summary set PercentOEE = ((PerformanceRate/100) * (AvailableRate/100) * (QualityRate/100)) * 100
update @Linesummary set PercentOEE = ((PerformanceRate/100) * (AvailableRate/100) * (QualityRate/100)) * 100
IF @ReturnType in( 1,2)
BEGIN
 	 IF @ReturnType  = 2  -- This is Unit Data so we want the unit desc
 	  	 UPDATE @Linesummary Set LineDesc = UnitDesc
 	 IF @AscDesc = 1
 	  	 SELECT 	 Line = LineDesc, LineId = UnitId,StartTime,EndTime,
 	  	  	 PerformanceRate = 
 	  	  	  	  	  	  	  	 CASE WHEN s.PerformanceRate > 100 AND @CapRates = 1  THEN 100
 	  	  	  	  	  	  	  	 ELSE coalesce(Round(s.PerformanceRate,0),0) END
 	  	  	  	  	  	  	  	 --coalesce(Round(s.PerformanceRate,0),0)
 	  	  	  	  	  	  	  	 ,
 	  	  	 QualityRate = CASE WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100 
 	  	  	  	  	  	  	 ELSE coalesce(Round(s.QualityRate,0),0) END,
 	  	  	 AvailableRate =  CASE WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	 ELSE coalesce(Round(s.AvailableRate,0),0) END,
 	  	  	 PercentOEE = 
 	  	  	  	  	  	  	 CASE WHEN s.PercentOEE > 100 AND @CapRates = 1 THEN 100 
 	  	  	  	  	  	  	 ELSE coalesce(Round(s.PercentOEE,0),0) END
 	  	  	  	  	  	  	 --coalesce(Round(s.PercentOEE,0),0)
 	  	  	  	  	  	  	 ,
 	  	  	 PerformanceThreshold = case WHEN s.PerformanceRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.PerformanceRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END,
 	  	  	 QualityThreshold = case WHEN s.QualityRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.QualityRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END ,
 	  	  	 AvailableThreshold = case WHEN s.AvailableRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END,
 	  	  	 OEEThreshold = case WHEN s.PercentOEE > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.PercentOEE > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END,
 	  	  	  	  	  	  	  	    
 	  	  	  	  	 LineStatus,OEEMode,MachineCount
  	  	 FROM @Linesummary s
 	  	 ORDER BY  CASE WHEN @SortOrder = 4 THEN LineDesc End,
 	  	  	  	  	 CASE WHEN @SortOrder = 1 THEN PerformanceRate 
 	  	  	  	  	   WHEN @SortOrder = 2 THEN QualityRate
 	  	  	  	  	   WHEN @SortOrder = 3 THEN AvailableRate
 	  	  	  	  	   ELSE PercentOEE  
 	  	  	  	 END DESC,LineDesc Asc
 	  	  	  	 OFFSET @pageSize *(@pageNum - 1) ROWS
 	  	   FETCH NEXT @pageSize ROWS ONLY; 
 	 ELSE
 	  	 SELECT 	 Line = LineDesc, LineId = UnitId,StartTime,EndTime,
 	  	  	 PerformanceRate = 
 	  	  	  	  	  	  	  	 CASE WHEN s.PerformanceRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	 ELSE coalesce(Round(s.PerformanceRate,0),0) END
 	  	  	  	  	  	  	  	 --coalesce(Round(s.PerformanceRate,0),0)
 	  	  	  	  	  	  	  	 ,
 	  	  	 QualityRate = CASE WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	 ELSE coalesce(Round(s.QualityRate,0),0) END,
 	  	  	 AvailableRate =  CASE WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	 ELSE coalesce(Round(s.AvailableRate,0),0) END,
 	  	  	 PercentOEE = 
 	  	  	  	  	  	  	 CASE WHEN s.PercentOEE > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	 ELSE coalesce(Round(s.PercentOEE,0),0) END
 	  	  	  	  	  	  	 --coalesce(Round(s.PercentOEE,0),0)
 	  	  	  	  	  	  	 ,
 	  	  	 PerformanceThreshold = case WHEN s.PerformanceRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.PerformanceRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END,
 	  	  	 QualityThreshold = case WHEN s.QualityRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.QualityRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END ,
 	  	  	 AvailableThreshold = case WHEN s.AvailableRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END,
 	  	  	 OEEThreshold = case WHEN s.PercentOEE > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.PercentOEE > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END,
 	  	  	 LineStatus ,OEEMode,MachineCount
 	  	 FROM @Linesummary s
 	  	 ORDER BY CASE WHEN @SortOrder = 4 THEN LineDesc End,
 	  	  	  	  CASE WHEN @SortOrder = 1 THEN PerformanceRate 
 	  	  	  	  	   WHEN @SortOrder = 2 THEN QualityRate
 	  	  	  	  	   WHEN @SortOrder = 3 THEN AvailableRate
 	  	  	  	  	   ELSE PercentOEE  
 	  	  	  	 END ASC,LineDesc Asc
 	  	  	  	 OFFSET @pageSize *(@pageNum - 1) ROWS
 	  	   FETCH NEXT @pageSize ROWS ONLY; 
END
IF @ReturnType = 3 
BEGIN
 	 DELETE FROM  @Linesummary WHERE  UnitDesc = 'All'
 	 IF @AscDesc = 1
 	  	 SELECT 	 Line = LineDesc, 
 	  	  	  	 Unit = UnitDesc,
 	  	  	  	 UnitId = UnitId,
 	  	  	  	 s.StartTime,
 	  	  	  	 s.EndTime,
 	  	  	 PerformanceRate = 
 	  	  	  	  	  	  	  	 CASE WHEN s.PerformanceRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	 ELSE coalesce(Round(s.PerformanceRate,0),0) END
 	  	  	  	  	  	  	  	 --coalesce(Round(s.PerformanceRate,0),0)
 	  	  	  	  	  	  	  	 ,
 	  	  	 QualityRate = CASE WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100 
 	  	  	  	  	  	  	 ELSE coalesce(Round(s.QualityRate,0),0) END,
 	  	  	 AvailableRate =  CASE WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	 ELSE coalesce(Round(s.AvailableRate,0),0) END,
 	  	  	 PercentOEE = 
 	  	  	  	  	  	  	 CASE WHEN s.PercentOEE > 100 AND @CapRates = 1 THEN 100 
 	  	  	  	  	  	  	 ELSE coalesce(Round(s.PercentOEE,0),0) END
 	  	  	  	  	  	  	 --coalesce(Round(s.PercentOEE,0),0)
 	  	  	  	  	  	  	 ,
 	  	  	 ClockedOn = Case WHEN a.UserId is null then 0 	 ELSE 1 END,
 	  	  	 Operator = Case When a.userid is Not Null Then u.Username
 	  	  	  	  	  	  	  	 else Null
 	  	  	  	  	  	  	  	 End,
 	  	  	 MachineRunning = Case When c.TEDet_Id is null THEN 1 ELSE 0  END,
 	  	  	  	  	  	 PerformanceThreshold = case WHEN s.PerformanceRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.PerformanceRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END,
 	  	  	 QualityThreshold = case WHEN s.QualityRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.QualityRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END ,
 	  	  	 AvailableThreshold = case WHEN s.AvailableRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END,
 	  	  	 OEEThreshold = case WHEN s.PercentOEE > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.PercentOEE > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END ,OEEMode,MachineCount
 	  	  	 FROM @Linesummary s
 	  	 Left Join User_Equipment_Assignment a on a.EquipmentId = s.UnitId and a.EndTime is null
 	  	 Left Join Users u on u.user_Id = a.UserId
 	  	 Left Join Timed_Event_Details c on c.pu_id = s.UnitId and c.End_Time Is Null
 	  	 ORDER BY CASE WHEN @SortOrder = 4 THEN UnitDesc End,
 	  	  	  	 Case WHEN @SortOrder = 1 THEN PerformanceRate 
 	  	  	  	  	   WHEN @SortOrder = 2 THEN QualityRate
 	  	  	  	  	   WHEN @SortOrder = 3 THEN AvailableRate
 	  	  	  	  	   ELSE PercentOEE  
 	  	  	  	 END DESC,UnitDesc Asc
 	  	  	  	 OFFSET @pageSize *(@pageNum - 1) ROWS
 	  	   FETCH NEXT @pageSize ROWS ONLY; 
 	 ELSE
 	  	 SELECT 	 Line = LineDesc, 
 	  	  	  	 Unit = UnitDesc,
 	  	  	  	 UnitId = UnitId,
 	  	  	  	 s.StartTime,
 	  	  	  	 s.EndTime,
 	  	  	  	 PerformanceRate = 
 	  	  	  	  	  	  	  	  	 CASE WHEN s.PerformanceRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	 ELSE coalesce(Round(s.PerformanceRate,0),0) END
 	  	  	  	  	  	  	  	  	 --coalesce(Round(s.PerformanceRate,0),0)
 	  	  	  	  	  	  	  	  	 ,
 	  	  	  	 QualityRate = CASE WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	 ELSE coalesce(Round(s.QualityRate,0),0) END,
 	  	  	  	 AvailableRate =  CASE WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	 ELSE coalesce(Round(s.AvailableRate,0),0) END,
 	  	  	  	 PercentOEE = 
 	  	  	  	  	  	  	  	 CASE WHEN s.PercentOEE > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	 ELSE coalesce(Round(s.PercentOEE,0),0) END
 	  	  	  	  	  	  	  	 --coalesce(Round(s.PercentOEE,0),0)
 	  	  	  	  	  	  	  	 ,
 	  	  	  	 ClockedOn = Case WHEN a.UserId is null then 0 	 ELSE 1 END,
 	  	  	  	 Operator = Case When a.userid is Not Null Then u.Username
 	  	  	  	  	  	  	  	  	 else Null
 	  	  	  	  	  	  	  	  	 End,
 	  	  	  	 MachineRunning = Case When c.TEDet_Id is null THEN 1 ELSE 0  END,
 	  	  	  	 PerformanceThreshold = case WHEN s.PerformanceRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.PerformanceRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END,
 	  	  	  	 QualityThreshold = case WHEN s.QualityRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.QualityRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END ,
 	  	  	  	 AvailableThreshold = case WHEN s.AvailableRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END,
 	  	  	 OEEThreshold = case WHEN s.PercentOEE > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	 WHEN s.PercentOEE > @Low      THEN 'Moderate'
 	  	  	  	  	  	  	  	    ELSE 'Poor'
 	  	  	  	  	  	  	  	    END ,OEEMode,MachineCount
 	  	 FROM @Linesummary s
 	  	 Left Join User_Equipment_Assignment a on a.EquipmentId = s.UnitId and a.EndTime is null
 	  	 Left Join Users u on u.user_Id = a.UserId
 	  	 Left Join Timed_Event_Details c on c.pu_id = s.UnitId and c.End_Time Is Null
 	  	 ORDER BY CASE WHEN @SortOrder = 4 THEN UnitDesc End, 
 	  	  	  	  CASE WHEN @SortOrder = 1 THEN PerformanceRate 
 	  	  	  	  	   WHEN @SortOrder = 2 THEN QualityRate
 	  	  	  	  	   WHEN @SortOrder = 3 THEN AvailableRate
 	  	  	  	  	   ELSE PercentOEE  
 	  	  	  	 END ASC,UnitDesc Asc
 	  	  	  	 OFFSET @pageSize *(@pageNum - 1) ROWS
 	  	   FETCH NEXT @pageSize ROWS ONLY; 
END
