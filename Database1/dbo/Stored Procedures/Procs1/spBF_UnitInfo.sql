CREATE PROCEDURE [dbo].[spBF_UnitInfo] 
@UnitList                nvarchar(max),
@StartTime               datetime = NULL,
@EndTime                 datetime = NULL,
@InTimeZone 	  	  	  	  nVarChar(200) = null,
@FilterNonProductiveTime int = 0,
@LineId 	  	  	  	  	 int = NULL
AS 
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
Declare @@EventId 	  	 int,
 	  	 @@MasterUnit 	 int,
 	  	 @@TimeStamp 	  	 datetime,
 	  	 @OEECalcType 	 Int,
 	  	 @Performance 	 Float,
 	  	 @ReworkTime 	  	 Float,
 	  	 @ConvertedST 	 DateTime,
 	  	 @ConvertedET 	 DateTime
DECLARE @ProductionAmount Float
DECLARE @IdealProductionAmount Float
DECLARE @PerformanceTbl TABLE (ProductionAmount Float,IdealProductionAmount Float)
  -- Declare local variables.
DECLARE @Units TABLE
  ( RowID int IDENTITY,
 	 UnitId int NULL ,
 	 Unit nVarChar(100) NULL,
 	 UnitOrder int null,
 	 LineId int NULL, 
 	 Line nVarChar(100) NULL,
 	 User_Id int,
 	 Username nvarchar(100),
 	 OEEType 	 Int Null
)
  Declare  @Events Table(
     UnitId int,
     Result_On datetime,
     Start_Time datetime,
     Event_Id int,
     Shop_Order nvarchar(100),  	 --Event_Num
     Event_Status tinyint,
     Event_Status_Desc nvarchar(50),
     Part_Number int, 	      	 --Product
     Part_Number_Desc nvarchar(50),
     Conformance tinyint,
     Testing_Prct_Complete tinyint,
     Quantity float,
     Quantity_Good float,
     Quantity_Bad float,
 	  User_Id int,
 	  Username nvarchar(100),
 	  Unit nvarchar(100),
 	  Unit2 nVarChar(100)
         )
SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@StartTime,@InTimeZone)
SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@EndTime,@InTimeZone)
if (@LineId is not null)
 	 begin
 	  	 insert into @Units (UnitId)
 	  	   Select PU_Id from Prod_Units where PL_Id = @LineId
 	 end
Else         
  if (@UnitList is not null)
 	 begin
 	  	 insert into @Units (UnitId)
 	  	 select Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,',')
 	 end
Declare Unit_Event_Cursor Insensitive Cursor
  For (Select UnitId from @Units)
  For Read Only
Open Unit_Event_Cursor
Fetch_Loop:
  Fetch Next From Unit_Event_Cursor Into @@MasterUnit
  If (@@FETCH_STATUS = 0)
    Begin
 	 Insert into @Events (Result_On,Start_Time,Event_Id,Shop_Order,Event_Status,
 	  	  	  	  	  	 Event_Status_Desc,Part_Number,Part_Number_Desc,Conformance,Testing_Prct_Complete,
 	  	  	  	  	  	 Quantity,Quantity_Good,Quantity_Bad,Unit,Unit2)
 	   Execute spBF_EventData @@MasterUnit, @StartTime, @EndTime, 1, @InTimeZone
 	   Update @Events set UnitId = @@MasterUnit where UnitId is null
 	   
      Goto Fetch_Loop
    End
 Close Unit_Event_Cursor
 Deallocate Unit_Event_Cursor
--Set Clocked on user based on Equipment (ignoring time of event)
Update @Units set User_Id = uea.UserId, Username = u.Username
  from @Units un  
  join dbo.User_Equipment_Assignment uea on uea.EquipmentId = un.UnitId
  join Users u on u.User_Id = uea.UserId
 	  	  	 Where UEA.EndTime IS NULL
update a
 	 Set OEEType = coalesce(b.Value,1) 
 	 From @Units a
 	 left Join dbo.Table_Fields_Values  b on b.KeyId = a.UnitId   AND b.Table_Field_Id = -91 AND B.TableId = 43
--Gather OEE Data
DECLARE
 	  	 @UnitRows 	  	  	  	  	  	 int,
 	  	 @Row 	  	  	  	  	  	  	 int,
 	  	 @ReportPUId 	  	  	  	  	  	 int,
 	  	 @oeeStatus 	  	  	  	  	  	 int
DECLARE @UnitSummary TABLE
(
 	 UnitID nvarchar(4000) null,
 	 IdealProductionAmount Float null,
 	 ProductionAmount Float null,
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
 	 ReworkTime 	 Float Default 0,
 	 CurrentStatusIcon tinyint null
)
-------------------------------------------------------------------------------------------------
-- Equipment/Unit translation
-------------------------------------------------------------------------------------------------
update u
 	 Set u.Unit = u1.PU_Desc,
 	  	 u.LineId = u1.PL_Id, 
 	  	 u.Line = l.PL_Desc,
 	  	 u.UnitOrder = coalesce(u1.PU_Order, 0)
 	 From @Units u
 	 Join dbo.Prod_Units u1 on u1.PU_Id = u.UnitId
 	 Join dbo.Prod_Lines l on l.PL_Id = u1.PL_ID
 	 
Select @UnitRows = COUNT(*) from @Units
Set @Row 	  	 = 	 0 	  
-- PRINT @UnitRows
-------------------------------------------------------------------------------------------------
-- Loop through units and get OEE Data
-------------------------------------------------------------------------------------------------
WHILE @Row <  @UnitRows
BEGIN
 	 SELECT @Row = @Row + 1
 	 SELECT @ReportPUID = UnitId,@OEECalcType = OEEType FROM @Units WHERE ROWID = @Row
 	 Insert Into @UnitSummary (
 	  	  	 UnitId,
 	  	  	 IdealSpeed,
 	  	  	 ActualSpeed,
 	  	  	 IdealProductionAmount,
 	  	  	 PerformanceRate,
 	  	  	 ProductionAmount, -- Net?
 	  	  	 WasteAmount,
 	  	  	 QualityRate,
 	  	  	 PerformanceTime,
 	  	  	 RunTime,
 	  	  	 LoadingTime,
 	  	  	 AvailableRate,
 	  	  	 PercentOEE
 	  	 )
 	 select 	 @ReportPUID,
 	  	  	 IdealSpeed,
 	  	  	 ActualSpeed,
 	  	  	 IdealProduction,
 	  	  	 PerformanceRate,
 	  	  	 NetProduction,
 	  	  	 Waste,
 	  	  	 QualityRate,
 	  	  	 PerformanceDowntime,
 	  	  	 RunTime,
 	  	  	 Loadtime,
 	  	  	 AvaliableRate,
 	  	  	 OEE
 	   from 	 fnBF_wrQuickOEESummary(@ReportPUID,@StartTime,@EndTime,@InTimeZone,@FilterNonProductiveTime,7,0)
 	   
 	   
 	 --*****************************************************
 	 -- Get Status
 	 --*****************************************************
 	 SELECT @oeeStatus = null
 	 SELECT @oeeStatus = Tedet_id
 	  	 FROM Timed_Event_Details WITH (NOLOCK)
 	  	 WHERE PU_Id = @ReportPUID and End_Time Is Null
 	 IF @oeeStatus Is Null
 	  	 SELECT @oeeStatus = 1
 	 ELSE
 	  	 SELECT @oeeStatus = 0
 	   
 	 UPDATE @UnitSummary
 	  	 SET CurrentStatusIcon 	 = 	 @oeeStatus
 	  	 WHERE UnitID = @ReportPUID
 	 IF @OEECalcType = 2 -- Long Running 840D
 	 BEGIN
 	  	 /* 	 
 	  	  	 Performance = Sum(ET)/Available Time
 	  	  	 Available Time = Calendar Time - Planned DT  	  	  	  	  	 
 	  	  	 ET = Equivalent Time (Variable providing runtime over interval) 	 
 	  	 */ 	 
  	    	  SELECT  @ProductionAmount = ProductionAmount/60.00
 	  	  	 FROM  dbo.fnCMN_Performance840D(@ReportPUID,@ConvertedST, @ConvertedET, @FilterNonProductiveTime) 
 	  	  SELECT @IdealProductionAmount = RunTime 
 	  	  	 FROM @UnitSummary
 	  	  	 WHERE UnitId = @ReportPUID
  	    	  UPDATE @UnitSummary SET IdealProductionAmount = @IdealProductionAmount,
  	    	    	    	    	  ProductionAmount = @ProductionAmount, -- Storing actual in net field
  	    	    	    	    	  PerformanceRate = CASE WHEN @IdealProductionAmount <= 0 THEN 0 ELSE @ProductionAmount/@IdealProductionAmount * 1.00 END
  	    	    	  WHERE UnitId = @ReportPUID
  	    	  SELECT @ReworkTime = dbo.fnCMN_QualityFromEvents(@ReportPUID,@ConvertedST, @ConvertedET,@FilterNonProductiveTime)/60.00 
  	    	  UPDATE @UnitSummary SET QualityRate = 1 - CASE WHEN @IdealProductionAmount <= 0 THEN 0 ELSE @ReworkTime/@IdealProductionAmount*1.00 END,
  	    	  	 ReworkTime = @ReworkTime
   	    	   WHERE UnitId = @ReportPUID
 	 END
 	 IF @OEECalcType = 3 --  Long Running EDM
 	 BEGIN
  	  	  INSERT INTO @PerformanceTbl(ProductionAmount,IdealProductionAmount)
  	    	    	  SELECT ProductionAmount,IdealProductionAmount 
  	    	    	  FROM dbo.fnCMN_PerformanceEDM(@ReportPUID,@ConvertedST, @ConvertedET,@FilterNonProductiveTime) 
  	    	  SELECT  @ProductionAmount = ProductionAmount,@IdealProductionAmount = IdealProductionAmount
  	    	    	  FROM @PerformanceTbl
  	    	  UPDATE @UnitSummary SET IdealProductionAmount = @IdealProductionAmount,
  	    	    	    	    	  ProductionAmount = @ProductionAmount, -- Storing actual in net field
  	    	    	    	    	  PerformanceRate = CASE WHEN @ProductionAmount <= 0 THEN 0 ELSE   @IdealProductionAmount/@ProductionAmount  * 1.00 END
  	    	    	  WHERE UnitId = @ReportPUID  	    	  
  	    	  SELECT @ReworkTime = dbo.fnCMN_QualityFromEvents(@ReportPUID,@ConvertedST, @ConvertedET,@FilterNonProductiveTime)/60.00
  	    	  UPDATE @UnitSummary SET QualityRate = 1 - CASE WHEN @ProductionAmount <= 0 THEN 0 ELSE @ReworkTime/@ProductionAmount *1.00 END,
  	    	  	 ReworkTime = @ReworkTime
  	    	   WHERE UnitId = @ReportPUID
 	 END
END
-------------------------------------------------------------------------------------------------
-- Final results
-------------------------------------------------------------------------------------------------
 SELECT u.UnitId, u.Unit, us.CurrentStatusIcon, u.User_Id, dbo.fnServer_CmnConvertFromDbTime(Result_On, @InTimeZone) as 'Result_On', 
 	 dbo.fnServer_CmnConvertFromDbTime(Start_Time, @InTimeZone) as 'Start_Time',Event_Id,Shop_Order,Part_Number,Part_Number_Desc,
 	 Quantity,Round(us.AvailableRate,0) as 'AvailableRate', Round(us.QualityRate,0) as 'QualityRate', Round(us.PerformanceRate,0) as 'PerformanceRate',
 	 Round(us.PercentOEE,0) as 'PercentOEE',
 	  	 PerformanceRateDesc = Case
 	  	  	  	  	  	 When PerformanceRate > 70 Then  -- /good
 	  	  	  	  	  	   'Good' 
 	  	  	  	  	  	 When PerformanceRate > 50 and PerformanceRate <= 70 then -- /fair
 	  	  	  	  	  	   'Fair'
 	  	  	  	  	  	 Else 	  	  	  	  	  	  	  	 -- /poor
 	  	  	  	  	  	   'Poor'
 	  	  	  	  	  	 End,
 	  	 QualiltyRateDesc = Case
 	  	  	  	  	  	 When QualityRate > 70 Then  -- /good
 	  	  	  	  	  	   'Good' 
 	  	  	  	  	  	 When QualityRate > 50 and QualityRate <= 70 then -- /fair
 	  	  	  	  	  	   'Fair'
 	  	  	  	  	  	 Else 	  	  	  	  	  	  	  	 -- /poor
 	  	  	  	  	  	   'Poor'
 	  	  	  	  	  	 End,
 	  	 AvailableRateDesc = Case
 	  	  	  	  	  	 When AvailableRate > 70 Then  -- /good
 	  	  	  	  	  	   'Good' 
 	  	  	  	  	  	 When AvailableRate > 50 and AvailableRate <= 70 then -- /fair
 	  	  	  	  	  	   'Fair'
 	  	  	  	  	  	 Else 	  	  	  	  	  	  	  	 -- /poor
 	  	  	  	  	  	   'Poor'
 	  	  	  	  	  	 End,
 	  	 PercentOEEDesc = Case
 	  	  	  	  	  	 When PercentOEE > 70 Then  -- /good
 	  	  	  	  	  	   'Good' 
 	  	  	  	  	  	 When PercentOEE > 50 and PercentOEE <= 70 then -- /fair
 	  	  	  	  	  	   'Fair'
 	  	  	  	  	  	 Else 	  	  	  	  	  	  	  	 -- /poor
 	  	  	  	  	  	   'Poor'
 	  	  	  	  	  	 End, u.Username 	  	 
 	 FROM @Units u
 	   Left outer Join @Events e on e.UnitID = u.UnitId
 	   Left outer Join @UnitSummary us on us.UnitID = u.UnitId
 	 ORDER BY u.UnitOrder
