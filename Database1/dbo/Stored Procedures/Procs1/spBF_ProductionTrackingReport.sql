CREATE PROCEDURE [dbo].[spBF_ProductionTrackingReport]
 	 --@PathList               nvarchar(max),
 	 @EquipmentType 	  	  	 int , --1 -unit ,2 - Line ,3 - Dept
 	 @EquipmentList 	  	  	 nvarchar(max), --when null get all lines paths 
 	 @StartTime              datetime = NULL,
 	 @EndTime                datetime = NULL,
 	 @InTimeZone 	             nVarChar(200) = null,
 	 @TimeSelection 	  	  	 Int = 1,
 	 @pageSize 	  	  	  	 Int = Null,
 	 @pageNum 	  	  	  	 Int = Null,
 	 @GroupBy 	  	  	     Int = 1
AS
set nocount on
DECLARE @ConvertedST Datetime
DECLARE @ConvertedET Datetime
DECLARE @PathRows Int
DECLARE @Row Int
DECLARE @CurrentPath Int
DECLARE @CurrentLine nvarchar(50)
DECLARE @CurrentLineID int
DECLARE @CurrentPathDesc nvarchar(50)
DECLARE @Now DATETIME
/*
 	  	 @TimeSelection = 1 /* Current Day  */
 	  	 @TimeSelection = 2 /* Prev Day     */
 	  	 @TimeSelection = 3 /* Current Week */
 	  	 @TimeSelection = 4 /* Prev Week    */
 	  	 @TimeSelection = 5 /* Next Week    */
 	  	 @TimeSelection = 6 /* Next Day     */
 	  	 @TimeSelection = 7 /* User Defined  Max 30 days*/
 	  	 Modified the code to have new Group By Logic 
*/
SET @EquipmentType = 1
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
IF @InTimeZone <> 'UTC'
BEGIN
 	 IF @StartTime Is Not Null  SELECT @StartTime = dbo.fnServer_CmnConvertTime (@StartTime , @InTimeZone,'UTC') 
 	 IF @EndTime Is Not Null SELECT @EndTime = dbo.fnServer_CmnConvertTime (@EndTime , @InTimeZone,'UTC') 
 	 SET @InTimeZone =  'UTC'
END
SELECT  @Now = dbo.fnServer_CmnConvertToDbTime(GetUTCDATE(),'UTC')
SET @Now = DATEADD(MILLISECOND,-DATEPART(MILLISECOND,@Now),@Now)
--EXECUTE dbo.spBF_CalculateOEEReportTime Null,@TimeSelection ,@StartTime  Output,@EndTime  Output,0
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
DECLARE @startRow 	 Int
DECLARE @endRow 	  	 Int
DECLARE @locallineid int
SET @pageNum = coalesce(@pageNum,1)
SET @pageSize = coalesce(@pageSize,10000)
SET @pageNum = @pageNum -1
SET @startRow = coalesce(@pageNum * @pageSize,0) + 1
SET @endRow = @startRow + @pageSize - 1
DECLARE @Paths TABLE  ( RowID int IDENTITY, PathId int NULL, PathDesc nVarChar(100) , LineId int NULL, 	  LineDesc nVarChar(100) NULL)
DECLARE @SortedPaths TABLE  ( RowID int IDENTITY, PathId int NULL, PathDesc nVarChar(100) , LineId int NULL,  LineDesc nVarChar(100) NULL)
DECLARE @PagePaths TABLE  ( RowID int IDENTITY, PathId int NULL, PathDesc nVarChar(100) , LineId int NULL, 	  LineDesc nVarChar(100) NULL)
DECLARE @ProdPlans TABLE  (PPId int NULL)
DECLARE @DistinctProdPlans TABLE  (PPId int NULL)
DECLARE @DistinctShift TABLE  (Crew_Desc nVarChar(100) NULL , Shift_Desc nVarChar(100) NULL , PU_Id int NULL,Start_Time date null ,End_Time date null  )
--bha
DECLARE @PathSummary TABLE
( 	 RowID int IDENTITY,
 	 PathId 	  	  	  	 Int,
 	 PPId 	  	  	  	 Int,
 	 StartTime 	  	  	 DateTime,
 	 EndTime 	  	  	  	 DateTime,
 	 CrewDesc 	  	  	 nvarchar(10),
 	 ShiftDesc 	  	  	 nvarchar(10),
 	 PUId 	  	  	  	 Int,
 	 PercentComplete 	  	 Float,
 	 PathDesc 	  	  	 nvarchar(50),
 	 LineDesc 	  	  	 nvarchar(50),
 	 LineID 	  	  	  	 int,
 	 UnitDesc 	  	  	 nvarchar(50),
 	 ProductCode 	  	  	 nvarchar(50),
 	 ProductDesc 	  	  	 nvarchar(50),
 	 ProcessOrder 	  	 nvarchar(50),
 	 ProcessOrderStatus  nvarchar(50),
 	 ProcessOrderControl 	 nvarchar(50),
 	 ProcessOrderType 	 nvarchar(50),
 	 ForecastQuantity 	 Float,
 	 ActualQuantity 	  	 Float,
 	 PredictedQuantity 	 Float,
 	 ForecastDuration 	  	 Float,
 	 ActualDuration 	  	 Float,
 	 PredictedDuration 	 Float
)
DECLARE @PathSummaryNoCrew TABLE
(  	 
  	 PathId 	  	  	  	 Int,
 	 PPId 	  	  	  	 Int,
 	 StartTime 	  	  	 DateTime,
 	 EndTime 	  	  	  	 DateTime,
 	 CrewDesc 	  	  	 nvarchar(10),
 	 ShiftDesc 	  	  	 nvarchar(10),
 	 PUId 	  	  	  	 Int,
 	 PercentComplete 	  	 Float,
 	 PathDesc 	  	  	 nvarchar(50),
 	 LineDesc 	  	  	 nvarchar(50),
 	 LineID 	  	  	  	 int,
 	 UnitDesc 	  	  	 nvarchar(50),
 	 ProductCode 	  	  	 nvarchar(50),
 	 ProductDesc 	  	  	 nvarchar(50),
 	 ProcessOrder 	  	 nvarchar(50),
 	 ProcessOrderStatus  nvarchar(50),
 	 ProcessOrderControl 	 nvarchar(50),
 	 ProcessOrderType 	 nvarchar(50),
 	 ForecastQuantity 	 Float,
 	 ActualQuantity 	  	 Float,
 	 PredictedQuantity 	 Float,
 	 ForecastDuration 	  	 Float,
 	 ActualDuration 	  	 Float,
 	 PredictedDuration 	 Float)
-------------------------------------------------------------------------------------------------
-- Unit translation
-------------------------------------------------------------------------------------------------
/*
If (@PathList is Not Null)
  	  Set @PathList = REPLACE(@PathList, ' ', '')
if ((@PathList is Not Null) and (LEN(@PathList) = 0))
  	  Set @PathList = Null
if (@PathList is not null)
BEGIN
  	    	  insert into @Paths (PathId)
  	    	  select Id from [dbo].[fnCmn_IdListToTable]('Prdexec_Paths',@PathList,',')
END
ELSE
BEGIN
 	 insert into @Paths (PathId) Select Path_id FROM Prdexec_Paths
END*/
DECLARE @Departments Table (DeptId 	 Int)
DECLARE @Units Table (PUId 	 Int)
DECLARE @Lines TABLE  ( RowID int IDENTITY, 	 LineId int NULL,LineDesc nvarchar(50))
if (@EquipmentList is not null)
BEGIN
 	 IF @EquipmentType = 3  -- Department
 	 BEGIN
 	  	 INSERT INTO @Departments(DeptId)
 	  	  	 SELECT Id from [dbo].[fnCmn_IdListToTable]('Departments',@EquipmentList,',')
 	  	 IF Not EXists(Select 1 FROM @Departments) -- Department Not Found
 	  	 BEGIN
 	  	  	 RETURN -999
 	  	 END
 	  	 INSERT INTO @Lines(LineId)
 	  	 SELECT PL_Id
 	  	 FROM Prod_Lines_Base a
 	  	 JOIN @Departments b on b.DeptId = a.Dept_Id
 	  	 --SET @EquipmentList = ''
 	  	 --SELECT @EquipmentList =  @EquipmentList + CONVERT(nvarchar(10),LineId) + ',' 
 	  	 -- 	  	 FROM @Lines
 	  	 --DELETE FROM @Lines  
 	  	 --SET @EquipmentType = 2
 	 END
 	 IF @EquipmentType = 1  -- Units
 	 BEGIN
 	  	 INSERT INTO @Units(PUId)
 	  	  	 SELECT Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@EquipmentList,',')
 	  	 IF Not EXists(Select 1 FROM @Units) -- Unit Not Found
 	  	 BEGIN
 	  	  	 RETURN -999
 	  	 END
 	  	 
 	  	 ;WITH NotConfiguredUnits As
 	  	 (
 	  	  	 Select 
 	  	  	  	 Pu.Pu_Id from Prod_Units_Base Pu
 	  	  	 Where
 	  	  	  	 Not Exists (Select 1 From Table_Fields_Values Where Table_Field_Id = -91 And TableId = 43 And KeyId = Pu.Pu_Id)
 	  	  	  	 AND Production_Rate_Specification IS NULL
 	  	 )
 	  	 Delete u
 	  	 from 
 	  	  	 @Units u 
 	  	  	 join NotConfiguredUnits nu on nu.PU_Id= u.PUId 	  
 	  	 
 	  	 
 	  	 INSERT INTO @Lines(LineId)
 	  	 SELECT  DISTINCT a.PL_Id
 	  	 FROM Prod_Units a
 	  	 JOIN @Units b on b.puid = a.pu_id
 	 END
 	 IF @EquipmentType = 2 -- Lines
 	 BEGIN
 	  	 INSERT into @Lines (LineId)
 	  	  	 SELECT Id from [dbo].[fnCmn_IdListToTable]('Prod_Lines',@EquipmentList,',')
 	  	 IF Not EXists(Select 1 FROM @Lines) -- Line Not Found
 	  	 BEGIN
 	  	  	 RETURN -999
 	  	 END
 	 END
END
--IF (@EquipmentList is null)
--BEGIN
-- 	 IF @EquipmentType = 3
-- 	 BEGIN
-- 	  	 INSERT into @Lines (LineId)
-- 	  	  	 SELECT PL_Id
-- 	  	  	  	 FROM Prod_Lines
-- 	  	  	  	 WHERE PL_Id > 0
-- 	 END
--END
SET @locallineid = (Select TOP 1 lineid from @Lines)
IF @StartTime IS NULL AND @EndTime IS NULL AND @TimeSelection != 7
EXECUTE dbo.spBF_CalculateOEEReportTime @locallineid,@TimeSelection ,@StartTime  Output,@EndTime  Output--,0
SELECT @StartTime = dbo.fnServer_CmnConvertToDbTime(@StartTime,@InTimeZone)
SELECT @EndTime = dbo.fnServer_CmnConvertToDbTime(@EndTime,@InTimeZone)
insert into @Paths (PathId) Select Path_id FROM Prdexec_Paths where pl_id in (Select lineid from @Lines)
update a
  	  Set a.LineId = b.PL_Id,
  	    	  a.LineDesc = l.PL_Desc,
 	  	  a.PathDesc = b.Path_Desc
  	  From @Paths a
 	  join Prdexec_Paths  b on b.Path_Id = a.PathId
  	  Join dbo.Prod_Lines l on l.PL_Id = b.PL_Id 
--test
--Select * from @Paths
SELECT @PathRows = Count(*) from @Paths
Set @Row  	    	  =  	  0  	   
 --PRINT @PathRows
-------------------------------------------------------------------------------------------------
-- Loop through units and get OEE Data
-------------------------------------------------------------------------------------------------
WHILE @Row <  @PathRows
BEGIN
 	 SELECT @Row = @Row + 1
 	 SELECT @CurrentPath = PathId,@CurrentPathDesc = a.PathDesc,@CurrentLine = a.LineDesc , @CurrentLineID = a.LineId 
 	  	 FROM @Paths a 
 	  	 WHERE ROWID = @Row
 	 INSERT INTO @ProdPlans(PPId)
 	  	 SELECT DIstinct a.PP_Id 
 	  	  	 From Production_Plan_Starts a 
 	  	  	 Join Production_Plan b on b.PP_Id = a.PP_Id 
 	  	  	 WHERE b.Path_Id = @CurrentPath and a.Start_Time  <= @EndTime  AND (a.End_Time  > @StartTime  or a.End_Time is null)
 	 --Select  'test1' as 'Test1 ',*,@Row from @ProdPlans
 	 INSERT INTO @ProdPlans(PPId)
 	  	 SELECT  a.PP_Id 
 	  	  	 From Production_Plan a 
 	  	  	 WHERE a.Path_Id = @CurrentPath and a.Actual_Start_Time  <= @EndTime  AND (a.Actual_End_Time  > @StartTime  or a.Actual_End_Time is null)
 	 --Select  'test2' as 'Test2 ',* ,@Row from @ProdPlans
 	 INSERT INTO @ProdPlans(PPId)
 	  	 SELECT  a.PP_Id 
 	  	  	 From Production_Plan a 
 	  	  	 WHERE a.Path_Id = @CurrentPath 
 	  	  	 AND a.Forecast_Start_Date   <= @EndTime  
 	  	  	 AND (a.Forecast_End_Date   > @StartTime  or a.Forecast_End_Date is null)
 	  	  	 AND Actual_Start_Time Is Null
 	 --Select  'test3' as 'Test3 ',* , @Row from @ProdPlans
 	 INSERT INTO @ProdPlans(PPId)
 	  	 SELECT  a.PP_Id 
 	  	  	 From Production_Plan a 
 	  	  	 WHERE a.Path_Id = @CurrentPath 
 	  	  	 AND a.Forecast_Start_Date   Is Null 
 	  	  	 AND Actual_Start_Time Is Null
 	  	 --Select  'test4' as 'Test4',* ,@Row from @ProdPlans
 	 
END
INSERT INTO @DistinctProdPlans (PPId)
 	  	 SELECT Distinct PPId FROM @ProdPlans
 	  	  	 
--Select 'test' as 'Test prod plans',* from @ProdPlans
--Select 'test' as 'Test distinct prod plans',* from @DistinctProdPlans
INSERT INTO @PathSummaryNoCrew (PathId,PathDesc,ProcessOrder,ProductDesc,StartTime,
  	  	  	  	  	  	  	  	 EndTime,CrewDesc,ShiftDesc,LineDesc,LineID , UnitDesc,
 	  	  	  	  	  	  	  	 PercentComplete, ActualQuantity,PUId,PPId,ProductCode,
 	  	  	  	  	  	  	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,ForecastQuantity,PredictedQuantity,
 	  	  	  	  	  	  	  	 ForecastDuration,ActualDuration,PredictedDuration)
SELECT  i.PathId,i.PathDesc,  --@CurrentPath,@CurrentPathDesc ,
b.Process_Order,c.Prod_Desc,
 	 Coalesce( b.Actual_Start_Time,b.Forecast_Start_Date),
 	 CASE WHEN b.PP_Status_Id != 3 THEN Coalesce( b.Actual_End_Time,b.Forecast_End_Date)
 	 ELSE DATEADD(MINUTE,b.Predicted_Total_Duration,b.Actual_Start_Time) END,
 	 'N/A',
 	 'N/A',
 	 --@CurrentLine,@CurrentLineID ,
 	 i.LineDesc,i.LineId,
 	 f.PU_Desc,
 	 CASE WHEN b.Forecast_Quantity < = 0 Then 0.0 
 	 ELSE
 	  	 (b.Actual_Good_Quantity  / b.Forecast_Quantity) * 100  
 	 END,
 	 coalesce(b.Actual_Good_Quantity,b.Forecast_Quantity) ,
 	 e.PU_Id,
 	 a.PPId,
 	 c.Prod_Code,
 	 d.PP_Status_Desc,
 	 h.Control_Type_Desc,
 	 g.PP_Type_Name,
 	 b.Forecast_Quantity,
 	 b.Predicted_Remaining_Quantity,
 	 datediff(MINUTE,b.Forecast_Start_Date ,b.Forecast_End_Date ),
 	 actual_running_time, --datediff(Minute,b.Actual_End_Time,b.Actual_End_Time),
 	 b.Predicted_Total_Duration
FROM @DistinctProdPlans a
Join  Production_plan b on b.PP_Id = a.PPId 
left join @paths i on b.Path_Id = i.PathId 
Left Join Products c on c.Prod_Id = b.Prod_Id 
Left Join Production_Plan_Statuses d on d.PP_Status_Id = b.PP_Status_Id
Left Join Production_Plan_Starts e on e.PP_Id = b.PP_Id  
Left Join Prod_Units f on f.PU_Id = e.PU_Id
Left Join Production_Plan_Types g on g.PP_Type_Id = b.PP_Type_Id   
Left Join Control_Type h on h.Control_Type_Id = b.Control_Type 
--select * from @PathSummaryNoCrew
INSERT INTO @PathSummary (PathId,PathDesc,ProcessOrder,ProductDesc,StartTime,
  	  	  	  	  	  	  	  	 EndTime,CrewDesc,ShiftDesc,LineDesc,LineID , UnitDesc, 
 	  	  	  	  	  	  	  	 PercentComplete, ActualQuantity,PUId,PPId,ProductCode,
 	  	  	  	  	  	  	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,ForecastQuantity,PredictedQuantity,
 	  	  	  	  	  	  	  	 ForecastDuration,ActualDuration,PredictedDuration)
SELECT PathId,PathDesc ,a.ProcessOrder,a.ProductDesc,
 	 --dbo.fnServer_CmnConvertFromDbTime(coalesce( a.StartTime,b.Start_Time),@InTimeZone),
 	 --dbo.fnServer_CmnConvertFromDbTime(coalesce(a.EndTime,b.End_Time),@InTimeZone),
 	 coalesce( a.StartTime,b.Start_Time), coalesce(a.EndTime,b.End_Time),
 	 b.Crew_Desc,b.Shift_Desc,a.LineDesc,a.LineID ,  a.UnitDesc, PercentComplete,
 	 ActualQuantity,PUId,PPId,ProductCode,ProcessOrderStatus,
 	 ProcessOrderControl,ProcessOrderType,ForecastQuantity,PredictedQuantity,ForecastDuration,
 	 ActualDuration,PredictedDuration
FROM @PathSummaryNoCrew a
Left Join Crew_Schedule b on b.PU_Id = a.PUId and b.Start_Time < EndTime and b.End_Time > StartTime 
AND b.End_Time > @StartTime
 	  	  	 AND b.Start_Time < @EndTime
ORDER BY PathDesc,Start_Time,ProcessOrder
IF @EquipmentType = 1 
BEGIN
-- This is for Group by none 
if @GroupBy = 1 
begin 
select distinct PathId,PathDesc,ProcessOrder,ProductDesc,
dbo.fnServer_CmnConvertFromDbTime(StartTime,@InTimeZone) as StartTime,
  	     dbo.fnServer_CmnConvertFromDbTime(EndTime,@InTimeZone) as EndTime,CrewDesc,ShiftDesc,LineDesc,LineID , UnitDesc, 
 	  	 PercentComplete = CASE WHEN PercentComplete < 100 AND PercentComplete > 0  THEN Convert(Decimal(3,0),PercentComplete) 
 	  	  	  	  	  	  	  	 WHEN PercentComplete <= 0 THEN 0 ELSE 100 END, 
 	  	 ActualQuantity = Convert(Decimal(20,2),ActualQuantity),
 	  	 PUId,PPId,ProductCode,
 	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,
 	  	 ForecastQuantity  = Convert(Decimal(20,2),ForecastQuantity),
 	  	 PredictedQuantity  = Convert(Decimal(20,2),PredictedQuantity),
 	  	 ForecastDuration  = Convert(Decimal(20,2),ForecastDuration),
 	  	 ActualDuration  = Convert(Decimal(20,2),ActualDuration),
 	  	 PredictedDuration  = Convert(Decimal(20,2),PredictedDuration)
 	  FROM @PathSummaryNoCrew  ps JOIN dbo.PrdExec_Path_Units pepu on ps.PathId = pepu.Path_Id
 	  --pepu.PU_Id IN(SELECT PUId  FROM @Units) where
 	  --WHERE RowID Between @startRow and @endRow And
 	  Where (ps.PUId In (SELECT PUId  FROM @Units) Or ps.PUId iS null) and  
 	  EndTime >= @StartTime and StartTime <= @EndTime
order by StartTime,ProcessOrder
end 
-- This is for group by Shift 
if @GroupBy = 2 
begin 
select distinct PathId,PathDesc,ProcessOrder,ProductDesc,
dbo.fnServer_CmnConvertFromDbTime(StartTime,@InTimeZone) as StartTime,
  	    dbo.fnServer_CmnConvertFromDbTime(EndTime,@InTimeZone) as EndTime,Null as CrewDesc,ShiftDesc,LineDesc,LineID , UnitDesc, 
 	  	 PercentComplete = CASE WHEN PercentComplete < 100 AND PercentComplete > 0  THEN Convert(Decimal(3,0),PercentComplete) 
 	  	  	  	  	  	  	  	 WHEN PercentComplete <= 0 THEN 0 ELSE 100 END,
 	  	 ActualQuantity = Convert(Decimal(20,2),ActualQuantity),
 	  	 PUId,PPId,ProductCode,
 	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,
 	  	 ForecastQuantity  = Convert(Decimal(20,2),ForecastQuantity),
 	  	 PredictedQuantity  = Convert(Decimal(20,2),PredictedQuantity),
 	  	 ForecastDuration  = Convert(Decimal(20,2),ForecastDuration),
 	  	 ActualDuration  = Convert(Decimal(20,2),ActualDuration),
 	  	 PredictedDuration  = Convert(Decimal(20,2),PredictedDuration)
 	  from @PathSummary ps JOIN dbo.PrdExec_Path_Units pepu on ps.PathId = pepu.Path_Id 
 	  WHERE (ps.PUId In (SELECT PUId  FROM @Units) Or ps.PUId iS null) AND
 	  EndTime >= @StartTime and StartTime <= @EndTime
 	  --RowID Between @startRow and @endRow  AND
order by StartTime,ProcessOrder
end 
-- This is for group by Crew 
if @GroupBy = 3 
begin 
select distinct PathId,PathDesc,ProcessOrder,ProductDesc,
dbo.fnServer_CmnConvertFromDbTime(StartTime,@InTimeZone) as StartTime,
  	   dbo.fnServer_CmnConvertFromDbTime(EndTime,@InTimeZone) as EndTime,CrewDesc,null as ShiftDesc,LineDesc,LineID , UnitDesc, 
 	  	 PercentComplete = CASE WHEN PercentComplete < 100 AND PercentComplete > 0  THEN Convert(Decimal(3,0),PercentComplete) 
 	  	  	  	  	  	  	  	 WHEN PercentComplete <= 0 THEN 0 ELSE 100 END,
 	  	 ActualQuantity = Convert(Decimal(20,2),ActualQuantity),
 	  	 PUId,PPId,ProductCode,
 	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,
 	  	 ForecastQuantity  = Convert(Decimal(20,2),ForecastQuantity),
 	  	 PredictedQuantity  = Convert(Decimal(20,2),PredictedQuantity),
 	  	 ForecastDuration  = Convert(Decimal(20,2),ForecastDuration),
 	  	 ActualDuration  = Convert(Decimal(20,2),ActualDuration),
 	  	 PredictedDuration  = Convert(Decimal(20,2),PredictedDuration)
 	  from @PathSummary ps JOIN dbo.PrdExec_Path_Units pepu on ps.PathId = pepu.Path_Id 
 	  WHERE (ps.PUId In (SELECT PUId  FROM @Units) Or ps.PUId iS null) AND
 	  EndTime >= @StartTime and StartTime <= @EndTime
 	  --RowID Between @startRow and @endRow AND
order by StartTime,ProcessOrder
end 
-- This is for group by Path - Only possible if equpment type is 1  
if @GroupBy = 4
begin 
select distinct PathId,PathDesc,ProcessOrder,ProductDesc,
 	  	 dbo.fnServer_CmnConvertFromDbTime(StartTime,@InTimeZone) as StartTime,
  	   dbo.fnServer_CmnConvertFromDbTime(EndTime,@InTimeZone) as EndTime,null as CrewDesc,null as ShiftDesc,LineDesc,LineID , UnitDesc, 
 	  	 PercentComplete = CASE WHEN PercentComplete < 100 AND PercentComplete > 0  THEN Convert(Decimal(3,0),PercentComplete) 
 	  	  	  	  	  	  	  	 WHEN PercentComplete <= 0 THEN 0 ELSE 100 END, 
 	  	 ActualQuantity = Convert(Decimal(20,2),ActualQuantity),
 	  	 PUId,PPId,ProductCode,
 	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,
 	  	 ForecastQuantity  = Convert(Decimal(20,2),ForecastQuantity),
 	  	 PredictedQuantity  = Convert(Decimal(20,2),PredictedQuantity),
 	  	 ForecastDuration  = Convert(Decimal(20,2),ForecastDuration),
 	  	 ActualDuration  = Convert(Decimal(20,2),ActualDuration),
 	  	 PredictedDuration  = Convert(Decimal(20,2),PredictedDuration)
 	  from @PathSummary ps JOIN dbo.PrdExec_Path_Units pepu on ps.PathId = pepu.Path_Id 
 	  WHERE (ps.PUId In (SELECT PUId  FROM @Units) Or ps.PUId iS null) AND
 	  EndTime >= @StartTime and StartTime <= @EndTime
 	  --RowID Between @startRow and @endRow AND
order by StartTime,ProcessOrder
end 
END
ELSE
BEGIN
-- This is for Group by none 
if @GroupBy = 1 
begin 
select distinct PathId,PathDesc,ProcessOrder,ProductDesc,
 	  	 dbo.fnServer_CmnConvertFromDbTime(StartTime ,@InTimeZone) as StartTime ,
  	     dbo.fnServer_CmnConvertFromDbTime(EndTime,@InTimeZone) as EndTime,CrewDesc,ShiftDesc,LineDesc,LineID , null as UnitDesc, 
 	  	 PercentComplete = CASE WHEN PercentComplete < 100 AND PercentComplete > 0  THEN Convert(Decimal(3,0),PercentComplete) 
 	  	  	  	  	  	  	  	 WHEN PercentComplete <= 0 THEN 0 ELSE 100 END,
 	  	 ActualQuantity = Convert(Decimal(20,2),ActualQuantity),
 	  	 Null as PUId,PPId,ProductCode,
 	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,
 	  	 ForecastQuantity  = Convert(Decimal(20,2),ForecastQuantity),
 	  	 PredictedQuantity  = Convert(Decimal(20,2),PredictedQuantity),
 	  	 ForecastDuration  = Convert(Decimal(20,2),ForecastDuration),
 	  	 ActualDuration  = Convert(Decimal(20,2),ActualDuration),
 	  	 PredictedDuration  = Convert(Decimal(20,2),PredictedDuration)
 	  from @PathSummaryNoCrew  where 
 	  EndTime >= @StartTime and StartTime <= @EndTime
order by StartTime,ProcessOrder
end 
-- This is for group by Shift 
if @GroupBy = 2 
begin 
select distinct PathId,PathDesc,ProcessOrder,ProductDesc,
 	  	 dbo.fnServer_CmnConvertFromDbTime(StartTime ,@InTimeZone) as StartTime ,
  	     dbo.fnServer_CmnConvertFromDbTime(EndTime,@InTimeZone) as 
 	  	 EndTime,Null as CrewDesc,ShiftDesc,LineDesc,LineID , Null as UnitDesc, 
 	  	 PercentComplete = CASE WHEN PercentComplete < 100 AND PercentComplete > 0  THEN Convert(Decimal(3,0),PercentComplete) 
 	  	  	  	  	  	  	  	 WHEN PercentComplete <= 0 THEN 0 ELSE 100 END, 
 	  	 ActualQuantity = Convert(Decimal(20,2),ActualQuantity),
 	  	 Null as PUId,PPId,ProductCode,
 	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,
 	  	 ForecastQuantity  = Convert(Decimal(20,2),ForecastQuantity),
 	  	 PredictedQuantity  = Convert(Decimal(20,2),PredictedQuantity),
 	  	 ForecastDuration  = Convert(Decimal(20,2),ForecastDuration),
 	  	 ActualDuration  = Convert(Decimal(20,2),ActualDuration),
 	  	 PredictedDuration  = Convert(Decimal(20,2),PredictedDuration)
 	  from @PathSummary 
 	  WHERE 
 	  EndTime >= @StartTime and StartTime <= @EndTime
 	 --RowID Between @startRow and @endRow And 
order by StartTime,ProcessOrder
end 
-- This is for group by Crew 
if @GroupBy = 3 
begin 
select distinct PathId,PathDesc,ProcessOrder,ProductDesc,
 	    dbo.fnServer_CmnConvertFromDbTime(StartTime ,@InTimeZone) as StartTime ,
  	    dbo.fnServer_CmnConvertFromDbTime(EndTime,@InTimeZone) as EndTime,CrewDesc,null as ShiftDesc,LineDesc,LineID , null as UnitDesc, 
 	  	 PercentComplete = CASE WHEN PercentComplete < 100 AND PercentComplete > 0  THEN Convert(Decimal(3,0),PercentComplete) 
 	  	  	  	  	  	  	  	 WHEN PercentComplete <= 0 THEN 0 ELSE 100 END,
 	  	 ActualQuantity = Convert(Decimal(20,2),ActualQuantity),
 	  	 null as PUId,PPId,ProductCode,
 	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,
 	  	 ForecastQuantity  = Convert(Decimal(20,2),ForecastQuantity),
 	  	 PredictedQuantity  = Convert(Decimal(20,2),PredictedQuantity),
 	  	 ForecastDuration  = Convert(Decimal(20,2),ForecastDuration),
 	  	 ActualDuration  = Convert(Decimal(20,2),ActualDuration),
 	  	 PredictedDuration  = Convert(Decimal(20,2),PredictedDuration)
 	  from @PathSummary 
 	  WHERE 
 	  EndTime >= @StartTime and StartTime <= @EndTime
 	  --RowID Between @startRow and @endRow And 
order by StartTime,ProcessOrder
end 
END
