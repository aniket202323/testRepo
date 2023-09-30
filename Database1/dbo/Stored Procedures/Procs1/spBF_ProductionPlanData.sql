/*
Get Production plan data set of Paths.
@PathList                - Comma separated list of production units, Null  = all paths
@StartTime               - Start time - For user defined time frame only
@EndTime                 - End time - For user defined time frame only
@InTimeZone              - Ex:'Central Stardard Time' - null defaults to database time
@TimeSelection             
 	  	  	  	 1 /* Current Day  */
 	  	  	  	 2 /* Prev Day     */
 	  	  	  	 3 /* Current Week */
 	  	  	  	 4 /* Prev Week    */
 	  	  	  	 5 /* Next Week    */
 	  	  	  	 6 /* Next Day     */
 	  	  	  	 7 /* User Defined  Max 30 days*/
@pageSize   - default 10000
@pageNum   - default 1
*/
--   execute spBF_ProductionPlanData Null,Null,null,null,1,10,1
CREATE PROCEDURE [dbo].[spBF_ProductionPlanData]
 	 @PathList               nvarchar(max),
 	 @StartTime              datetime = NULL,
 	 @EndTime                datetime = NULL,
 	 @InTimeZone 	             nVarChar(200) = null,
 	 @TimeSelection 	  	  	 Int = 1,
 	 @pageSize 	  	  	  	 Int = Null,
 	 @pageNum 	  	  	  	 Int = Null
AS
set nocount on
DECLARE @ConvertedST Datetime
DECLARE @ConvertedET Datetime
DECLARE @PathRows Int
DECLARE @Row Int
DECLARE @CurrentPath Int
DECLARE @CurrentLine nvarchar(50)
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
*/
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
EXECUTE dbo.spBF_CalculateOEEReportTime  Null,@TimeSelection ,@StartTime  Output,@EndTime  Output,0
DECLARE @startRow 	 Int
DECLARE @endRow 	  	 Int
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
SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@StartTime,@InTimeZone)
SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@EndTime,@InTimeZone)
-------------------------------------------------------------------------------------------------
-- Unit translation
-------------------------------------------------------------------------------------------------
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
END
update a
  	  Set a.LineId = b.PL_Id,
  	    	  a.LineDesc = l.PL_Desc,
 	  	  a.PathDesc = b.Path_Desc
  	  From @Paths a
 	  join Prdexec_Paths  b on b.Path_Id = a.PathId
  	  Join dbo.Prod_Lines l on l.PL_Id = b.PL_Id
SELECT @PathRows = Count(*) from @Paths
Set @Row  	    	  =  	  0  	   
 --PRINT @PathRows
-------------------------------------------------------------------------------------------------
-- Loop through units and get OEE Data
-------------------------------------------------------------------------------------------------
WHILE @Row <  @PathRows
BEGIN
 	 SELECT @Row = @Row + 1
 	 SELECT @CurrentPath = PathId,@CurrentPathDesc = a.PathDesc,@CurrentLine = a.LineDesc 
 	  	 FROM @Paths a 
 	  	 WHERE ROWID = @Row
 	 INSERT INTO @ProdPlans(PPId)
 	  	 SELECT DIstinct a.PP_Id 
 	  	  	 From Production_Plan_Starts a 
 	  	  	 Join Production_Plan b on b.PP_Id = a.PP_Id 
 	  	  	 WHERE b.Path_Id = @CurrentPath and a.Start_Time  <= @ConvertedET  AND (a.End_Time  > @ConvertedST  or a.End_Time is null)
 	 INSERT INTO @ProdPlans(PPId)
 	  	 SELECT  a.PP_Id 
 	  	  	 From Production_Plan a 
 	  	  	 WHERE a.Path_Id = @CurrentPath and a.Actual_Start_Time  <= @ConvertedET  AND (a.Actual_End_Time  > @ConvertedST  or a.Actual_End_Time is null)
 	 INSERT INTO @ProdPlans(PPId)
 	  	 SELECT  a.PP_Id 
 	  	  	 From Production_Plan a 
 	  	  	 WHERE a.Path_Id = @CurrentPath 
 	  	  	 AND a.Forecast_Start_Date   <= @ConvertedET  
 	  	  	 AND (a.Forecast_End_Date   > @ConvertedST  or a.Forecast_End_Date is null)
 	  	  	 AND Actual_Start_Time Is Null
 	 INSERT INTO @ProdPlans(PPId)
 	  	 SELECT  a.PP_Id 
 	  	  	 From Production_Plan a 
 	  	  	 WHERE a.Path_Id = @CurrentPath 
 	  	  	 AND a.Forecast_Start_Date   Is Null 
 	  	  	 AND Actual_Start_Time Is Null
 	  	  	 
END
INSERT INTO @DistinctProdPlans (PPId)
 	  	 SELECT Distinct PPId FROM @ProdPlans
INSERT INTO @PathSummaryNoCrew (PathId,PathDesc,ProcessOrder,ProductDesc,StartTime,
  	  	  	  	  	  	  	  	 EndTime,CrewDesc,ShiftDesc,LineDesc,UnitDesc,
 	  	  	  	  	  	  	  	 PercentComplete, ActualQuantity,PUId,PPId,ProductCode,
 	  	  	  	  	  	  	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,ForecastQuantity,PredictedQuantity,
 	  	  	  	  	  	  	  	 ForecastDuration,ActualDuration,PredictedDuration)
SELECT i.PathId,i.PathDesc,  
 	  	 b.Process_Order,c.Prod_Desc,
 	 Coalesce(e.Start_Time, b.Actual_Start_Time,b.Forecast_Start_Date),
 	 Case WHEN b.Actual_Start_Time Is Null Then Coalesce(e.End_Time,b.Actual_End_Time,b.Forecast_End_Date)
 	  	 ELSE
 	  	  Coalesce(b.Actual_End_Time,@Now)
 	  	 END,
 	 'N/A',
 	 'N/A',
 	 i.LineDesc, 
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
 	 datediff(Minute,b.Forecast_Start_Date ,b.Forecast_End_Date ),
 	 actual_running_time,
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
INSERT INTO @PathSummary (PathId,PathDesc,ProcessOrder,ProductDesc,StartTime,
  	  	  	  	  	  	  	  	 EndTime,CrewDesc,ShiftDesc,LineDesc,UnitDesc,
 	  	  	  	  	  	  	  	 PercentComplete, ActualQuantity,PUId,PPId,ProductCode,
 	  	  	  	  	  	  	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,ForecastQuantity,PredictedQuantity,
 	  	  	  	  	  	  	  	 ForecastDuration,ActualDuration,PredictedDuration)
SELECT PathId,PathDesc ,a.ProcessOrder,a.ProductDesc,
 	 coalesce(b.Start_Time, a.StartTime),
 	 coalesce(b.End_Time,a.EndTime),
 	 b.Crew_Desc,b.Shift_Desc,a.LineDesc,a.UnitDesc,PercentComplete,
 	 ActualQuantity,PUId,PPId,ProductCode,ProcessOrderStatus,
 	 ProcessOrderControl,ProcessOrderType,ForecastQuantity,PredictedQuantity,ForecastDuration,
 	 ActualDuration,PredictedDuration
FROM @PathSummaryNoCrew a
Left Join Crew_Schedule b on b.PU_Id = a.PUId and b.Start_Time < EndTime and b.End_Time > StartTime
ORDER BY PathDesc,Start_Time,ProcessOrder
select PathId,PathDesc,ProcessOrder,ProductDesc
 	  	 ,StartTime = dbo.fnServer_CmnConvertFromDbTime(StartTime,@InTimeZone)
 	  	 ,EndTime = dbo.fnServer_CmnConvertFromDbTime(EndTime,@InTimeZone)
 	  	 ,CrewDesc,ShiftDesc,LineDesc,UnitDesc,
 	  	 PercentComplete = CASE WHEN Percentcomplete > 100 Then 100 else Convert(Decimal(3,0),PercentComplete) END , --KP Capping percent to 100 to avoid arthmetic exceptions
 	  	 ActualQuantity = Convert(Decimal(20,2),ActualQuantity),
 	  	 PUId,PPId,ProductCode,
 	  	 ProcessOrderStatus,ProcessOrderControl,ProcessOrderType,
 	  	 ForecastQuantity  = Convert(Decimal(20,2),ForecastQuantity),
 	  	 PredictedQuantity  = Convert(Decimal(20,2),PredictedQuantity),
 	  	 ForecastDuration  = Convert(Decimal(20,2),ForecastDuration),
 	  	 ActualDuration  = Convert(Decimal(20,2),ActualDuration),
 	  	 PredictedDuration  = Convert(Decimal(20,2),PredictedDuration)
 	  from @PathSummary 
 	  WHERE RowID Between @startRow and @endRow
order by StartTime,ProcessOrder
