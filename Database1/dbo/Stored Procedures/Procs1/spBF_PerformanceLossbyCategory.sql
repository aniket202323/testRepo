CREATE Procedure [dbo].[spBF_PerformanceLossbyCategory]
@UnitList text = null,
@StartTime datetime = null,
@EndTime datetime = null,
@FilterNonProductiveTime int = 0,
@ShowTopNBars int = 20,
@InTimeZone 	  	 nVarChar(200) = NULL,  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
@TimeOption int = null
AS
--**************************************************/
set arithignore on
set arithabort off
set ansi_warnings off
DECLARE @@UnitId int, @@UnitDesc nvarchar(50)
DECLARE @SQL1 nVarChar(3000)
DECLARE @SQL2 nVarChar(3000)
DECLARE @SQL3 nVarChar(3000)
DECLARE @SQL4 nVarChar(3000)
DECLARE @FaultId int
DECLARE @TreeId int
DECLARE @Level1Name nVarChar(100)
DECLARE @Level2Name nVarChar(100)
DECLARE @Level3Name nVarChar(100)
DECLARE @Level4Name nVarChar(100)
DECLARE @PerformanceCategory int, @OutsideAreaCategory int, @UnavailableCategory int
DECLARE @iIdealProduction real,  
 	  	  	  	 @iIdealYield real,  
 	  	  	  	 @iActualProduction real,
 	  	  	  	 @iActualQualityLoss real,
 	  	  	  	 @iActualYieldLoss real,
 	  	  	  	 @iActualSpeedLoss real,
 	  	  	  	 @iActualDowntimeLoss real,
 	  	  	  	 @iActualDowntimeMinutes real,
 	  	  	  	 @iActualRuntimeMinutes real,
 	  	  	  	 @iActualUnavailableMinutes real,
 	  	  	  	 @iActualSpeed real,
 	  	  	  	 @iActualPercentOEE real,
 	  	  	  	 @iActualTotalItems int,
 	  	  	  	 @iActualGoodItems int,
 	  	  	  	 @iActualBadItems int,
 	  	  	  	 @iActualConformanceItems int,
 	  	  	  	 @iTargetProduction real,
 	  	  	  	 @iWarningProduction real,  
 	  	  	  	 @iRejectProduction real,  
 	  	  	  	 @iTargetQualityLoss real,
 	  	  	  	 @iWarningQualityLoss real,
 	  	  	  	 @iRejectQualityLoss real,
 	  	  	  	 @iTargetDowntimeLoss real,
 	  	  	  	 @iWarningDowntimeLoss real,
 	  	  	  	 @iRejectDowntimeLoss real,
 	  	  	  	 @iTargetSpeed real,
 	  	  	  	 @iTargetDowntimeMinutes real,
 	  	  	  	 @iWarningDowntimeMinutes real,
 	  	  	  	 @iRejectDowntimeMinutes real,
 	  	  	  	 @iTargetPercentOEE real,
 	  	  	  	 @iWarningPercentOEE real,
 	  	  	  	 @iRejectPercentOEE real,
 	  	  	  	 @iAmountEngineeringUnits nvarchar(25),
 	  	  	  	 @iItemEngineeringUnits nvarchar(25),
 	  	  	  	 @iTimeEngineeringUnits int,
 	  	  	  	 @iStatus int,
 	  	  	  	 @iActualDowntimeCount int
DECLARE @SpeedLossTime real , @PerformanceDT real, @NetOperatingTime real, @DesignTime real
Create TABLE #Summary (
  Timestamp  	  	 datetime,
  ProductId 	   	 int NULL,
  LocationId  	      	 int NULL,
  Reason1  	  	 int NULL,
  Reason2  	  	 int NULL,
  Reason3  	  	 int NULL,
  Reason4  	  	 int NULL,
  Category nvarchar(1000) NULL,
  Duration  	  	 real NULL,
  TimeToRepair  	  	 real NULL,
  TimePreviousFailure   real NULL,
  Fault  	  	 nVarChar(100) NULL,
  Crew 	  	  	 nvarchar(10) NULL,
 	 Shift 	  	  	 nvarchar(10) NULL 	 
) 
DECLARE @TotalOperatingTime int
DECLARE @TotalDownTime real
SELECT @TotalOperatingTime = 0
SELECT @TotalDownTime = 0.0
--*****************************************************/
--Build List Of Units
--*****************************************************/
DECLARE  @Units TABLE
(
Id int Identity(1,1),
  LineName nVarChar(100) NULL, 
  LineId int NULL,
 	 UnitName nVarChar(100) NULL,
 	 Item int
)
create TABLE #ProductiveTimes
(
  PU_Id     int null,
  StartTime datetime,
  EndTime   datetime
)
 /*Time Options are also need to consider */
Create TABLE  #TimeOptions (Option_Id int, Date_Type_Id int, Description nvarchar(50), Start_Time datetime, End_Time datetime)
 IF(@StartTime) IS NOT NULL AND (@EndTime) IS NOT NULL
BEGIN
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END
ELSE IF (@TimeOption) IS NOT NULL
BEGIN
 	 INSERT INTO #TimeOptions exec spRS_GetTimeOptions @TimeOption,@InTimeZone
 	 SELECT @StartTime = Start_Time, @EndTime = End_Time FROM #TimeOptions
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	  	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END
ELSE
BEGIN
 	 INSERT INTO #TimeOptions exec spRS_GetTimeOptions 30,@InTimeZone -- Default to Today if no start time and end time is provided
 	 SELECT @StartTime = Start_Time, @EndTime = End_Time FROM #TimeOptions 	 
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END 
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
  begin
    if (not @UnitList like '%<Root>%')
    begin
      DECLARE @UnitText nVarChar(4000)
      SELECT @UnitText = N'Item;' + Convert(nVarChar(4000), @UnitList)
      INSERT INTO @Units (Item) EXECUTE spDBR_Prepare_TABLE @UnitText
    end
    else
    begin
      INSERT INTO @Units EXECUTE spDBR_Prepare_TABLE @UnitList
    end
  end
Else
  Begin
    INSERT INTO @Units (Item) 
      SELECT distinct pu_id FROM prod_events where event_type = 2     
  End
--*****************************************************/
--Exclude Units
;WITH NotConfiguredUnits As
 	  	 (
 	  	  	 Select 
 	  	  	  	 Pu.Pu_Id from Prod_Units Pu
 	  	  	 Where
 	  	  	  	 Not Exists (Select 1 From Table_Fields_Values Where Table_Field_Id = -91 And TableId = 43 And KeyId = Pu.Pu_Id)
 	  	  	  	 AND Production_Rate_Specification IS NULL
 	  	 )
Delete U 
FROM 
 	 @Units U 
WHERE EXISTS (SELECT 1 FROM NotConfiguredUnits Where PU_Id = U.Item)
 	 Declare @tempUnits TABLE (
 	  	  	 RowID int IDENTITY(1, 1), 
 	  	  	 curPU_Id int)
 	 --Declare  @tempProductiveTime TABLE
 	 --(RowNum INT Identity (1,1),
 	 -- 	 PU_Id     int null,
 	 -- 	 StartTime datetime,
 	 -- 	 EndTime   datetime)
 	 DECLARE @curPU_Id int
 	 Insert into @tempUnits
      	 SELECT Item FROM @Units
 	 DECLARE @NumberRecords int, @RowCount int
 	 SET @NumberRecords = @@ROWCOUNT
 	 SET @RowCount = 1
 	 WHILE @RowCount <= @NumberRecords
 	 BEGIN
 	     SELECT @curPU_Id = curPU_Id FROM @tempUnits WHERE RowID = @RowCount
 	  
 	  	 IF (@FilterNonProductiveTime = 1)
 	  	 BEGIN
 	  	  	 
 	  	  	 INSERT INTO #ProductiveTimes (StartTime, EndTime)
 	  	  	  	  	 EXECUTE spDBR_GetProductiveTimes  @curPU_Id, @StartTime, @EndTime
 	  	  	 update #ProductiveTimes set PU_Id = @curPU_Id where PU_Id is null
   	 
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	  	 INSERT INTO #ProductiveTimes (PU_Id, StartTime, EndTime) 
 	  	  	  	  	 SELECT @curPU_Id, @StartTime, @EndTime
 	  	 END
 	  	 SET @RowCount = @RowCount + 1
 	 END
Create TABLE #OperatingTime (
  ProductId int,
  TotalTime int 
) 
 	 --Prepare Details TABLE
Create TABLE #Details (
  Timestamp  	  	 datetime,
  LocationId 	  	 int NULL,
  ProductId 	  	  	 int NULL,
  Reason1  	  	  	 int NULL,
  Reason2  	  	  	 int NULL,
  Reason3  	  	  	 int NULL,
  Reason4  	  	  	 int NULL,
  Category 	  	  	 nvarchar(1000) NULL,
  Duration  	  	  	 real NULL,
  TimeToRepair  	  	 real NULL,
  TimePreviousFailure  	 real NULL,
  FaultId  	  	  	 int NULL,
 	 Crew 	  	  	 nvarchar(10) null,
  Shift 	  	  	 nvarchar(10) NULL,
) 
Create TABLE #ProductChanges (
ProductId int,
StartTime datetime,
EndTime datetime,
) 
Create TABLE #Shift (
ShiftDesc  	 nvarchar(10),
ShiftStart  	 DateTime,
ShiftEnd 	   	 DateTime
)
DECLARE @ProductionShortFall FLOAT
DECLARE @LocalUnitSummary TABLE 
(
 	 LocationId 	  	 int,
 	 LocationDesc  	  	 nvarchar(50),
 	 PerformanceLoss 	  	 real,
 	 NormalizedRateLoss 	 real,
 	 TotalTime 	  	 real
) 	  	 
DECLARE @curStartTime datetime, @curEndTime datetime
Declare @OEEType nvarchar(20)
DECLARE @maxunits int = (SELECT count(*) FROM @Units)
DECLARE @currentId int  = 1
While @currentId <= @maxunits
 	 Begin
 	  	 SELECT @curStartTime = NULL
 	  	 SELECT @curEndTime = NULL
 	  	 SELECT @@UnitId = Item FROM @Units where Id = @currentId
 	  	 DECLARE TIME_CURSOR INSENSITIVE CURSOR
 	  	   For ( SELECT StartTime, EndTime FROM #ProductiveTimes where PU_Id = @@UnitId )
 	  	   For Read Only
 	  	   Open TIME_CURSOR  
 	  	 BEGIN_TIME_CURSOR:
 	  	 Fetch Next FROM TIME_CURSOR INTO @curStartTime, @curEndTime
 	  	 While @@Fetch_Status = 0
 	  	  	 Begin    
 	  	  	  	 
 	  	  	  	 execute spCMN_GetUnitStatistics @@UnitId,@curStartTime,@curEndTime,@iIdealProduction OUTPUT,@iIdealYield OUTPUT,@iActualProduction OUTPUT,@iActualQualityLoss OUTPUT,@iActualYieldLoss OUTPUT,@iActualSpeedLoss OUTPUT,@iActualDowntimeLoss OUTPUT,@iActualDowntimeMinutes OUTPUT,@iActualRuntimeMinutes OUTPUT,@iActualUnavailableMinutes OUTPUT,@iActualSpeed OUTPUT,@iActualPercentOEE OUTPUT,@iActualTotalItems OUTPUT,@iActualGoodItems OUTPUT,@iActualBadItems OUTPUT,@iActualConformanceItems OUTPUT,@iTargetProduction OUTPUT,@iWarningProduction OUTPUT,@iRejectProduction OUTPUT,@iTargetQualityLoss OUTPUT,@iWarningQualityLoss OUTPUT,@iRejectQualityLoss OUTPUT,@iTargetDowntimeLoss OUTPUT,@iWarningDowntimeLoss OUTPUT,@iRejectDowntimeLoss OUTPUT,@iTargetSpeed OUTPUT,@iTargetDowntimeMinutes OUTPUT,@iWarningDowntimeMinutes OUTPUT,@iRejectDowntimeMinutes OUTPUT,@iTargetPercentOEE OUTPUT,@iWarningPercentOEE OUTPUT,@iRejectPercentOEE OUTPUT,@iAmountEngineeringUnits OUTPUT,@iItemEngineeringUnits OUTPUT,@iTimeEngineeringUnits OUTPUT,@iStatus OUTPUT,@iActualDowntimeCount OUTPUT
 	  	  	  	 SELECT @PerformanceCategory = Coalesce(Performance_Downtime_Category, 0), @@UnitDesc = pu_desc FROM Prod_Units Where PU_Id = @@UnitId
 	  	  	  	 SELECT @OutsideareaCategory = Coalesce(Downtime_External_Category, 0), @@UnitDesc = pu_desc FROM Prod_Units Where PU_Id = @@UnitId
 	  	  	  	 SELECT @UnavailableCategory = Coalesce(Downtime_Scheduled_Category, 0), @@UnitDesc = pu_desc FROM Prod_Units Where PU_Id = @@UnitId
 	  	 
 	  	  	  	 -- Need to make iTargetSpeed in minutes
 	  	  	  	 SELECT @iTargetSpeed = Case
 	  	  	  	  	 When @iTimeEngineeringUnits = 0 Then @iTargetSpeed / 60.0 -- hours
 	  	  	  	  	 When @iTimeEngineeringUnits = 1 Then @iTargetSpeed 	  	   -- Minutes
 	  	  	  	  	 When @iTimeEngineeringUnits = 2 Then @iTargetSpeed * 60.0 -- Seconds
 	  	  	  	  	 When @iTimeEngineeringUnits = 3 Then @iTargetSpeed / 1440 -- Days
 	  	  	  	  	 End
 	  	  	  	 --<TIME BASED UNITS>
 	  	  	  	 Select 
 	  	  	  	  	    @OEEType = EDFTV.Field_desc
 	  	  	  	 From 
 	  	  	  	  	    Table_Fields TF
 	  	  	  	  	    JOIN Table_Fields_Values TFV on TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = TF.TableId
 	  	  	  	  	    Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
 	  	  	  	  	    LEFT OUTER Join ED_FieldType_ValidValues EDFTV on EDFTV.ED_Field_Type_Id = TF.ED_Field_Type_Id AND EDFTV.Field_Id = TFV.Value
 	  	  	  	 Where 
 	  	  	  	  	    TF.Table_Field_Desc = 'OEE Calculation Type'
 	  	  	  	  	    and TFV.KeyID =@@UnitId
 	  	  	  	 Select @PerformanceCategory = Erc_Id from Event_reason_Catagories Where Erc_Desc = 'Performance'  AND ISNULL(@OEEType,'') = 'Time Based'
 	  	  	  	 --</TIME BASED UNITS>
 	  	  	  	 SELECT @PerformanceDT = dbo.fnCMN_GetCategoryTimeByUnit(@curStartTime,@curEndTime,@@UnitId, @PerformanceCategory, null)
 	  	  	  	 SELECT @PerformanceDT = @PerformanceDT / 60
 	  	  	  	 -- This line represents Production Shortfall                                    (Ideal Production)   -    (ActualProduction)   / IdealSpeed
 	  	  	  	 SELECT @SpeedLossTime = Case When @iTargetSpeed = 0 then 0 else((@iActualRuntimeMinutes * @iTargetSpeed) - @iActualProduction) / @iTargetSpeed end
 	  	  	  	 SELECT @SpeedLossTime = isnull(@SpeedLossTime, 0)
 	  	  	  	 SELECT @NetOperatingTime = Case When @iActualRuntimeMinutes < @SpeedLossTime then 0 else @iActualRuntimeMinutes - @SpeedLossTime end
 	  	  	  	 SELECT @DesignTime = Case When @NetOperatingTime < @PerformanceDT then 0 else @NetOperatingTime - @PerformanceDT end
 	  	  	  	 -- new calcs
 	  	  	  	 SELECT @ProductionShortFall = @iIdealProduction - (@iActualProduction + @iActualQualityLoss)-- [ProductionShortfall]
 	  	  	  	 SELECT @NetOperatingTime = @iActualRuntimeMinutes - @PerformanceDT --[NetOperatingTime]
 	  	  	  	 SELECT @SpeedLossTime = Case When @iTargetSpeed = 0 then 0 else @ProductionShortFall / @iTargetSpeed End -- [SpeedLossTime]
 	  	  	  	 SELECT @DesignTime = @iActualRuntimeMinutes - @SpeedLossTime
 	  	  	  	 --Get Reason Level Header Names
 	  	  	  	 If @Level1Name Is Null
 	  	  	  	  	 Begin
     	  	  	  	  	 SELECT @TreeId = Name_Id
 	  	  	  	  	  	   FROM Prod_Events
 	  	  	  	  	  	   Where PU_Id = @@UnitId and
 	  	  	  	  	  	 Event_Type = 2
     	  	  	  	  	 SELECT @Level1Name = level_name
 	  	  	  	  	  	   FROM event_reason_level_headers 
 	  	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	  	  	  	 Reason_Level = 1
      	  	  	  	  	 If @Level1Name Is Not Null 
 	  	   	  	  	  	  	 SELECT @Level2Name = level_name
 	  	  	  	  	  	  	   FROM event_reason_level_headers 
 	  	  	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	  	  	  	  	 Reason_Level = 2
 	  	  	  	 
 	  	  	  	  	  	 If @Level2Name Is Not Null 
 	  	  	  	  	  	  	 SELECT @Level3Name = level_name
 	  	  	  	  	  	  	   FROM event_reason_level_headers 
 	  	  	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	  	  	  	  	 Reason_Level = 3
 	  	  	  	  	  	 
 	  	  	  	  	  	 If @Level3Name Is Not Null 
 	  	  	  	  	  	  	 SELECT @Level4Name = level_name
 	  	  	  	  	  	  	   FROM event_reason_level_headers 
 	  	  	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	  	  	  	  	 Reason_Level = 4
 	  	  	  	  	 End
 	  	  	  	 SELECT @SQL1 = 'SELECT d.Start_Time, d.Source_PU_Id, d.Reason_Level1, d.Reason_Level2, d.Reason_Level3, d.Reason_Level4,erc.ERC_Desc_Local' 	  
 	  	  	  	 SELECT @SQL1 = @SQL1 + ', Datediff(second, Case When d.Start_Time < ' + '''' + convert(nvarchar(30),@curStartTime) + '''' + ' Then ' + '''' + convert(nvarchar(30),@curStartTime) + '''' + ' Else d.Start_Time End, Case When d.End_Time > ' + '''' + convert(nvarchar(30),@curEndTime) + '''' + ' Then ' + '''' + convert(nvarchar(30),@curEndTime) + '''' + ' Else coalesce(d.End_Time, ' + '''' + convert(nvarchar(30),@curEndTime) + '''' + ') End) / 60.0'
 	  	  	  	 SELECT @SQL1 = @SQL1 + ', Datediff(second, d.Start_Time, coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0'
 	  	  	  	 SELECT @SQL1 = @SQL1 + ', Case When d.Start_Time < ' + '''' + convert(nvarchar(30),@curStartTime) + '''' + ' Then Null When d.Uptime <= 0 Then null else d.Uptime End'
 	  	  	  	 SELECT @SQL1 = @SQL1 + ', d.TEFault_Id'
 	  	  	  	 SELECT @SQL1 = @SQL1 + ' FROM Timed_Event_Details d left outer join event_reason_category_data c on c.event_reason_tree_data_id = d.event_reason_tree_data_id left outer join Event_reason_Catagories erc on c.erc_id = erc.erc_id'
 	  	  	  	  
 	  	  	  	 SELECT @SQL1 = @SQL1 + ' Where d.PU_Id = ' + convert(nvarchar(10),@@UnitId)
 	  	  	  	 SELECT @SQL1 = @SQL1 + ' and c.erc_id in (' 	  + convert(nVarChar(5),@PerformanceCategory) + ',' + convert(nVarChar(5),@OutsideareaCategory) + ',' + convert(nVarChar(5),@UnavailableCategory) + ')'
 	  	  	  	 SELECT @SQL2 = ' and d.Start_Time >= ' + '''' + convert(nvarchar(30),@curStartTime) + '''' + ' and d.Start_Time < ' + '''' + convert(nvarchar(30),@curEndTime) + ''''
 	  	  	  	 SELECT @SQL2 = 
 	  	  	  	  	 CASE 
 	  	  	  	  	  	 WHEN @FilterNonProductiveTime = 1 
 	  	  	  	  	  	 THEN ' AND ( d.Start_Time between '+''''+convert(nvarchar(30),@curStartTime)+''' AND '+'''' + convert(nvarchar(30),@curEndTime) + ''' OR 
 	  	  	  	  	  	 d.end_Time between '+''''+convert(nvarchar(30),@curStartTime)+''' AND '+'''' + convert(nvarchar(30),@curEndTime) + ''') '
 	  	  	  	  	 ELSE
 	  	  	  	  	  	 ' and d.Start_Time >= ' + '''' + convert(nvarchar(30),@curStartTime) + '''' + ' and d.Start_Time < ' + '''' + convert(nvarchar(30),@curEndTime) + ''''
 	  	  	  	  	 END
 	  	  	 
 	  	 
 	  	  	  	 SELECT @SQL4 = @SQL1 + @SQL2
 	  	  	  	 INSERT INTO #Details (Timestamp, LocationId, Reason1, Reason2, Reason3, Reason4, Category, Duration, TimeToRepair, TimePreviousFailure, FaultId)
 	  	  	  	 Exec (@SQL4)   
 	  	  	  	  
 	  	  	  	 SELECT @SQL2 = ' and d.Start_Time = (SELECT Max(t.Start_Time) FROM Timed_Event_Details t Where t.PU_Id = ' + convert(nvarchar(10),@@UnitId) 
 	  	  	  	 SELECT @SQL2 = @SQL2 + ' and t.start_time < ' + '''' + convert(nvarchar(30),@curStartTime) + '''' + ') and ((d.End_Time > ' + '''' + convert(nvarchar(30),@curStartTime) + '''' + ') or (d.End_Time is Null))'
 	  	  	  	 SELECT @SQL4 = @SQL1 + @SQL2 + @SQL3
 	  	  	  	 
 	  	  	  	 INSERT INTO #Details (Timestamp, LocationId, Reason1, Reason2, Reason3, Reason4, Category, Duration, TimeToRepair, TimePreviousFailure, FaultId)
 	  	  	  	 Exec (@SQL4)  
 	  	  	  	 
 	  	  	  	 
 	  	  	  	 
 	  	  	  	 -- Join In Product Information    
 	  	  	  	 Update #Details 
 	  	  	  	 Set ProductId = (SELECT Prod_Id FROM Production_Starts ps Where ps.PU_Id = @@UnitId and ps.Start_Time <= #Details.Timestamp and ((ps.End_Time > #Details.Timestamp) or (ps.End_Time Is Null)))      	 
 	  	  	  	 INSERT INTO #ProductChanges (ProductId, StartTime, EndTime)
 	  	  	  	   SELECT Prod_Id, 
 	  	  	  	  	  	  Case When Start_Time < @curStartTime Then @curStartTime Else Start_Time End,
 	  	  	  	  	  	  Case When coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) > @curEndTime Then @curEndTime Else coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) End
 	  	  	  	  	 FROM Production_Starts d
 	  	  	  	  	   Where d.PU_id = @@UnitId and
 	   	  	  	  	  	  	  	   d.Start_Time = (SELECT Max(t.Start_Time) FROM Production_Starts t Where t.PU_Id = @@UnitId and t.start_time < @curStartTime) and
 	   	  	  	  	  	  	   ((d.End_Time > @curStartTime) or (d.End_Time is Null))
 	  	  	  	    Union
 	  	  	  	  	 SELECT Prod_Id, 
 	  	  	  	  	  	  Case When Start_Time < @curStartTime Then @curStartTime Else Start_Time End,
 	  	  	  	  	  	  Case When coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) > @curEndTime Then @curEndTime Else coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) End
 	  	  	  	  	 FROM Production_Starts d
 	  	  	  	  	  	 Where d.PU_id = @@UnitId and
 	  	  	  	  	  	  	   d.Start_Time >= @curStartTime and 
 	          	  	  	  	  	 d.Start_Time < @curEndTime 
 	  	  	  	 SELECT @TotalOperatingTime = @TotalOperatingTime + coalesce((SELECT sum(datediff(second, StartTime, EndTime))FROM #ProductChanges),0)
    	  	  	  	 INSERT INTO #OperatingTime (ProductId, TotalTime)
 	  	  	  	   SELECT ProductId, sum(datediff(second, StartTime, EndTime))
 	  	  	  	  	 FROM #ProductChanges
 	  	  	  	  	 Group By ProductId
 	  	  	        
 	  	  	  	 truncate TABLE #ProductChanges    
 	  	  	  	 --Update Crew
 	  	  	  	 Update #Details 
 	  	  	  	   Set #Details.Crew = (SELECT c.Crew_Desc FROM Crew_Schedule c Where c.PU_Id = @@UnitId and c.Start_Time <= #Details.Timestamp and C.End_Time > #Details.Timestamp)
 	  	  	 
 	  	  	     
 	  	  	  	 -- Add Rows To Summary Resultset
 	  	  	  	 INSERT INTO  #Summary (Timestamp,ProductId,LocationId,Reason1,Reason2,Reason3,Reason4,Category, Duration, TimeToRepair, TimePreviousFailure, Crew,Shift, Fault) 
 	  	  	  	  	 SELECT Timestamp,
 	  	  	  	  	  	 ProductId,
 	  	  	  	  	  	 LocationId,
 	  	  	  	  	  	 Reason1,
 	  	  	  	  	  	 Reason2,
 	  	  	  	  	  	 Reason3,
 	  	  	  	  	  	 Reason4,
 	  	  	  	  	  	 Category,
 	  	  	  	  	  	 Duration, 
 	  	  	  	  	  	 TimeToRepair, 
 	  	  	  	  	  	 TimePreviousFailure, 
 	  	  	  	  	  	 Crew, 
 	  	  	  	  	  	 Shift,
 	  	  	  	  	  	 case when tef.TEFault_Id Is Null then dbo.fnDBTranslate(N'0', 38333, 'Unspecified') Else tef.TEFault_Name End 
 	  	  	  	  	 FROM #Details
 	  	  	  	  	 Left Outer Join Timed_Event_Fault tef on tef.TEFault_Id = #Details.FaultId 
 	  	   	  	 SELECT @TotalDownTime = @TotalDownTime + coalesce((SELECT sum(Duration) FROM #Details),0)
 	  	  	  	 INSERT INTO @LocalUnitSummary (LocationId, LocationDesc, PerformanceLoss, NormalizedRateLoss, TotalTime) 
 	  	  	  	 values (@@UnitId, @@UnitDesc, @PerformanceDT, @SpeedLossTime, @PerformanceDT + @SpeedLossTime) 
 	  	  	  	 Truncate TABLE #Details
 	  	  	  	 Truncate TABLE #Shift
 	  	  	 GOTO BEGIN_TIME_CURSOR
 	  	 End
 	 Close TIME_CURSOR
 	 Deallocate TIME_CURSOR
 	 SELECT @currentId = @currentId + 1
End
 SELECT CASE WHEN Category = 'Performance' then 'Performance Loss' Else Category End Category, SUM(Cast(Duration as float)) 
 AS 'Total Time', COUNT(Duration) AS 'Events'
        FROM #Summary
        GROUP BY Category
 	    ORDER BY 'Total Time' DESC
DROP TABLE #Summary
DROP TABLE #ProductiveTimes
DROP TABLE #OperatingTime
DROP TABLE #Details
DROP TABLE #ProductChanges
DROP TABLE #Shift
DROP TABLE #TimeOptions
