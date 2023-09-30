CREATE PROCEDURE dbo.spSDK_QueryProductionEvents
   	 @iLineMask 	  	  	 nvarchar(50) 	  	  	 = NULL,
   	 @iUnitMask 	  	  	 nvarchar(50) 	  	  	 = NULL,
   	 @iEventMask   	    nvarchar(50) 	  	  	 = NULL,
   	 @iStartTime   	    DATETIME 	  	  	  	 = NULL,
   	 @iEndTime 	  	  	 DATETIME 	  	  	  	 = NULL,
 	   @iEventStatus 	  	 nvarchar(50) 	  	  	 = NULL,
   	 @iProductCode 	  	 nvarchar(50) 	  	  	 = NULL,
   	 @iUserId 	  	  	  	 INT 	  	  	  	  	 = NULL,
   	 @iDeptMask 	  	  	 nvarchar(50) 	  	  	 = NULL --Department is irrelevant because Line still has to be unique so just ignore it
AS 
/*------------------------------------------------
ECR#30268:
The SP was performing very fast when run from Query Analyzer, but if I tried to run 
it from ADO (SDK, Server Class, or straight ADO) it would take up to 90 seconds to run 
sometimes...  After a lot of searching, I came accross this thread: 
http://sqlteam.com/forums/topic.asp?TOPIC_ID=41378&whichpage=1
It describes a similar situation and identified the fix to be declaring additional 
varaibles inside the SP which match with the input variables, copying the input 
values to these new variables and using the new variables in the SP.  It makes no 
sense to me as to why this would matter, but sure enough, it seems to have solved 
the problem. 
--for testing
dbo.spSDK_QueryProductionEvents_SubEventNum 'P15Z0249',1
dbo.spSDK_QueryProductionEvents 
'Paper Line #*',
'p* Machine',
'*15Z0249',
'2005-12-01 14:08:00.000', '2005-12-03 14:08:00.000',NULL,NULL, 1, NULL 
*/
--Department is irrelevant because Line still has to be unique so just ignore it
SET 	 @iDeptMask = ISNULL(@iDeptMask, 'Department')
DECLARE 	 @LineMask 	  	  	 nvarchar(50),
 	  	    	 @UnitMask 	  	  	 nvarchar(50),
 	  	    	 @EventMask   	    nvarchar(50),
 	  	    	 @StartTime   	    DATETIME,
 	  	    	 @EndTime 	  	  	 DATETIME,
 	  	  	 @EventStatus 	  	 nvarchar(50),
 	  	    	 @ProductCode 	  	 nvarchar(50),
 	  	    	 @UserId 	  	  	  	 INT
SET 	 @LineMask = @iLineMask
SET 	 @UnitMask = @iUnitMask
SET 	 @EventMask = @iEventMask
SET 	 @StartTime = @iStartTime
SET 	 @EndTime = @iEndTime
SET 	 @EventStatus = @iEventStatus
SET 	 @ProductCode = @iProductCode
SET 	 @UserId = @iUserId
-- Declarations
-- Initialization
SET 	 @LineMask 	  	 = REPLACE(ISNULL(@LineMask, '*'), '*', '%')
SET   	 @LineMask 	  	 = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SET 	 @UnitMask 	  	 = REPLACE(ISNULL(@UnitMask, '*'), '*', '%')
SET 	 @UnitMask 	  	 = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SET 	 @EventMask 	  	 = REPLACE(ISNULL(@EventMask, '*'), '*', '%')
SET 	 @EventMask 	  	 = REPLACE(REPLACE(@EventMask, '?', '_'), '[', '[[]')
SET 	 @EventStatus 	 = ISNULL(@EventStatus, '%')
SET 	 @ProductCode 	 = ISNULL(@ProductCode, '%')
/*
If the line/unit/eventnum are all supplied (no wildcards), just ignore the timestamp 
If the line/unit/eventStatus are all supplied (no wildcards), just ignore the timestamp 
*/
IF CHARINDEX('%',@LineMask) = 0 AND   CHARINDEX('%',@UnitMask) = 0 
  BEGIN  
    IF CHARINDEX('%',@EventMask) = 0 and CHARINDEX('_',@EventMask) = 0
      BEGIN
        exec dbo.spSDK_QueryProductionEvents_SubUnitEventNum
       	 @LineMask 	  	  	 ,
       	 @UnitMask 	  	  	 ,
       	 @EventMask   	 ,
       	 @iUserId 	  	  	 
        return
      END
/*
    ELSE IF CHARINDEX('%',@EventStatus) = 0 AND CHARINDEX('%',@ProductCode) = 0 
      BEGIN
        exec dbo.spSDK_QueryProductionEvents_SubUnitStatusProduct
       	 @LineMask 	  	  	 ,
       	 @UnitMask 	  	  	 ,
       	 @EventStatus  	 ,
       	 @ProductCode  	 ,
       	 @iUserId 	  	  	 
        return
      END
*/
    ELSE IF CHARINDEX('%',@EventStatus) = 0 and CHARINDEX('_',@EventStatus) = 0
      BEGIN
        exec dbo.spSDK_QueryProductionEvents_SubUnitStatus
       	 @LineMask 	  	  	 ,
       	 @UnitMask 	  	  	 ,
       	 @EventStatus  ,
       	 @iUserId 	  	  	 
        return
      END
  END
ELSE IF @LineMask = '%' AND 	 @UnitMask = '%'
  BEGIN
    IF CHARINDEX('%',@EventMask) = 0 and CHARINDEX('_',@EventMask) = 0
      BEGIN
        exec dbo.spSDK_QueryProductionEvents_SubEventNum
       	 @EventMask   	 ,
       	 @iUserId 	  	  	 
        return
      END
  END
IF @EndTime IS NULL
BEGIN
 	 IF @StartTime IS NULL
 	 BEGIN
 	  	 SELECT @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
 	 END ELSE
 	 BEGIN
 	  	 SELECT @EndTime = DATEADD(DAY, 1, @StartTime)
 	 END
END
IF @StartTime IS NULL
BEGIN
 	 IF @EventMask = '%'
 	 BEGIN
 	  	 SET 	  	 @StartTime = DATEADD(DAY, -1, @EndTime)
 	 END ELSE
 	 BEGIN
 	  	 SELECT 	 @StartTime = MIN(ISNULL(Start_Time, Timestamp))
 	  	  	 FROM 	 Events e 	  	  	 
 	  	  	 JOIN 	 Prod_Units pu 	 ON 	 pu.PU_Id = e.PU_Id
 	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	  	  	 JOIN 	 Prod_Lines pl 	 ON 	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	 AND pl.PL_Desc LIKE @LineMask
 	  	  	 WHERE 	 Event_Num 	  	 LIKE 	 @EventMask
 	 END
END
--CREATE TABLE #EventList (  	  -- MKW 2005-03-02
-- DECLARE @EventList TABLE (
--  	  	    	   Event_Id   	      	    INT,
--  	  	    	   DepartmentName   	    nvarchar(50),
--  	  	    	   LineName   	      	    nvarchar(50),
--  	  	    	   UnitName   	      	    nvarchar(50),
--  	  	    	   EventName   	      	    nvarchar(50),
--  	  	    	   EventType   	      	    nvarchar(50),
--  	  	    	   EventStatus 	  	  	  	 nvarchar(50),
--  	  	    	   TestingStatus   	      	 nvarchar(50),
--  	  	    	   OriginalProduct 	  	  	 nvarchar(50),
--  	  	    	   AppliedProduct 	  	  	 nvarchar(50),
--  	  	    	   ProcessOrder 	  	  	  	 nvarchar(50),
--  	  	    	   StartTime   	      	    DATETIME,
--  	  	    	   EndTime   	      	      	 DATETIME,
--  	  	    	   IX   	      	      	    FLOAT,
--  	  	    	   IY   	      	      	    FLOAT,
--  	  	    	   IZ   	      	      	    FLOAT,
--  	  	    	   IA   	      	      	    FLOAT,
--  	  	    	   FX   	      	      	    FLOAT,
--  	  	    	   FY   	      	      	    FLOAT,
--  	  	    	   FZ   	      	      	    FLOAT,
--  	  	    	   FA   	      	      	    FLOAT,
--  	  	    	   CommentId   	      	    INT,
--  	  	    	   ExtendedInfo   	      	 nVarChar(255)
--  	  	 )
--CREATE TABLE #pus (
DECLARE @pus TABLE(  	  --RowId  	  int IDENTITY,
 	  	  	 PU_Id 	  	  	  	 INT, --PRIMARY KEY
 	  	  	 Dept_Desc 	  	 nvarchar(50),
 	  	  	 PL_Desc 	  	  	 nvarchar(50),
 	  	  	 PU_Desc 	  	  	 nvarchar(50)
--  	    	    	    	  Unique(RowId),
 	  	  	 UNIQUE(PU_Id)
)
--CREATE TABLE #ProductChanges (
DECLARE @ProductChanges TABLE (  	  PU_Id  	    	  INT,
  	    	    	    	    	    	    	  Prod_Id  	    	  INT,
  	    	    	    	    	    	    	  Start_Time  	  DATETIME,
  	    	    	    	    	    	    	  End_Time  	    	  DATETIME NULL,
  	    	    	    	    	    	    	  PRIMARY KEY(PU_Id, Start_Time)
)
--CREATE INDEX ProdChange ON #ProductChanges (PU_Id, Start_Time)
--CREATE TABLE #ProcessOrders (
DECLARE @ProcessOrders TABLE (  	  PU_Id  	    	    	  INT,
  	    	    	    	    	    	    	  ProcessOrder  	    	  nvarchar(50),
  	    	    	    	    	    	    	  Start_Time  	    	  DATETIME,
  	    	    	    	    	    	    	  End_Time  	    	    	  DATETIME NULL,
  	    	    	    	    	    	    	  PRIMARY KEY(PU_Id, Start_Time)
)
--CREATE INDEX ProcOrder ON #ProcessOrders (PU_Id, Start_Time)
-- Filter to the Prod_Units that are specified.
--INSERT INTO   	   #pus
INSERT INTO 	 @pus
 	 SELECT 	 pu.PU_Id, d.Dept_Desc, pl.PL_Desc, pu.PU_Desc
 	  	 FROM 	 Prod_Lines pl
 	  	 INNER JOIN 	 Departments d 	  	 ON 	 d.Dept_Id = pl.Dept_Id
 	  	 INNER JOIN 	 Prod_Units pu 	  	 ON 	 pu.PL_Id = pl.PL_Id 
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc 	 LIKE 	 @UnitMask
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0
 	  	 LEFT JOIN 	 User_Security pls 	 ON 	  	 pl.Group_id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	  	 LEFT JOIN 	 User_Security pus 	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId
 	  	 WHERE 	 pl.PL_Desc 	 LIKE 	 @LineMask 
 	  	 AND 	 COALESCE(pus.Access_Level, ISNULL(pls.Access_Level, 3)) >= 2
-- Get Product Changes Between Time Range
--INSERT INTO #ProductChanges (PU_Id, Prod_id, Start_Time, End_Time)
INSERT INTO @ProductChanges (PU_Id, Prod_id, Start_Time, End_Time)
 	 SELECT   	   ps.PU_Id, Prod_id, Start_Time, End_Time
 	  	 FROM Production_Starts ps
 	  	 INNER JOIN 	 @pus pu 	 ON 	  	 ps.PU_Id = pu.PU_Id
 	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0  	    	  -- helps with index
 	 -- 	 WHERE PU_Id IN (SELECT pu_id FROM #pus)
 	 -- 	 WHERE  	  ps.Start_Time >= @StartTime
 	 --  	    	  AND ps.Start_Time <= @EndTime
 	  	 WHERE 	 ps.Start_Time < @EndTime
 	  	 AND 	 (ps.End_Time > @StartTime
 	  	  	 OR 	 ps.End_Time IS NULL)
-- Get Process Orders Between Time Range
--INSERT INTO #ProcessOrders (PU_Id, ProcessOrder, Start_Time, End_Time)
INSERT INTO @ProcessOrders (PU_Id, ProcessOrder, Start_Time, End_Time)
 	 SELECT 	 ps.PU_Id, pp.Process_Order, ps.Start_Time, ps.End_Time
 	  	 FROM 	 Production_Plan_Starts ps
 	  	 INNER JOIN @pus pu 	  	  	  	 ON 	  	 ps.PU_Id = pu.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0  	    	  -- helps with index
 	  	 INNER JOIN Production_Plan pp 	 ON pp.pp_id = ps.pp_id 
--   	 WHERE 	 ps.PU_id IN (SELECT PU_Id FROM #pus)
-- 	  	 WHERE 	 ps.Start_Time >= @StartTime
-- 	  	 AND 	 ps.Start_Time <= @EndTime
 	  	 WHERE 	 ps.Start_Time < @EndTime
 	  	 AND 	 (ps.End_Time > @StartTime
 	  	  	 OR 	 ps.End_Time IS NULL)
-- Get Product Change, Process Order Right Before Time Range For Each Unit 
-- DECLARE 	 @@PU_Id 	  	  	 INT,
--  	  	  	 @@Start_Time 	 DATETIME
-- 
--DECLARE UnitCursor INSENSITIVE CURSOR
--  FOR SELECT PU_Id FROM @pus
--  FOR READ ONLY
--OPEN UnitCursor
--Fetch_Loop:
--WHILE (@Row < @Rows)
--  	  BEGIN
--  	  SELECT @Row = @Row + 1
--  	  SELECT @@PU_Id = PU_Id
--  	  FROM @pus
--  	  WHERE RowId = @Row
--   	   FETCH NEXT FROM UnitCursor INTO @@PU_Id
--   	   IF @@FETCH_STATUS = 0 
--   	   BEGIN
-- Needed to get the first event that overlaps the current range
--   	      	   SELECT   	   @@Start_Time = MAX(Start_Time)
--  	      	      	   FROM   	   Production_Starts 
--   	      	      	   WHERE   	   PU_Id = @@PU_Id
--   	      	      	   AND   	   Start_Time < @StartTime
--   	      	      	   AND    	   (End_Time > @StartTime OR End_Time IS NULL) 
--   	      	   INSERT INTO #ProductChanges (PU_Id, Prod_id, Start_Time, End_Time)
--   	      	   INSERT INTO @ProductChanges (PU_Id, Prod_id, Start_Time, End_Time)
--   	      	      	   SELECT   	   PU_Id, Prod_id, Start_Time, End_Time
--   	      	      	      	   FROM   	   Production_Starts 
--   	      	      	      	   WHERE PU_id = @@PU_Id
--   	      	      	      	   AND   	   Start_Time = @@Start_Time 
--      SELECT   	   @@Start_Time = NULL
--      SELECT   	   @@Start_Time = MAX(Start_Time)
--   	      	      	   FROM   	   Production_Plan_Starts 
--   	      	      	   WHERE   	   PU_Id = @@PU_Id
--   	      	      	   AND   	   Start_Time < @StartTime 
--   	      	      	   AND    	   (End_Time > @StartTime OR End_Time IS NULL) 
--      IF @@Start_Time IS NOT NULL
--   	      	   BEGIN
--   	      	      	   INSERT INTO #ProcessOrders (PU_Id, ProcessOrder, Start_Time, End_Time)
--   	      	      	   INSERT INTO @ProcessOrders (PU_Id, ProcessOrder, Start_Time, End_Time)
--            SELECT   	   ps.PU_Id, pp.Process_Order, ps.Start_Time, ps.End_Time
--   	      	      	      	      	   FROM   	   Production_Plan_Starts ps
--   	      	      	      	      	   JOIN   	   Production_Plan pp   	      	      	   ON pp.pp_id = ps.pp_id 
--   	      	      	      	      	   WHERE   	   ps.PU_Id = @@PU_Id
--   	      	      	      	      	   AND   	   ps.Start_Time = @@Start_Time 
--   	      	   END
--   	      	   GOTO Fetch_Loop
--   	   END
--CLOSE   	   UnitCursor
--DEALLOCATE   	   UnitCursor 
--INSERT   	   #EventList   	   (Event_Id,DepartmentName,LineName,UnitName,EventName,EventType,EventStatus,TestingStatus,OriginalProduct,
-- INSERT   	   @EventList   	   (Event_Id,DepartmentName,LineName,UnitName,EventName,EventType,EventStatus,TestingStatus,OriginalProduct,
--    	      	      	      	      	      	      	    AppliedProduct,ProcessOrder,StartTime,EndTime,IX,IY,IZ,IA,FX,FY,FZ,FA,CommentId,ExtendedInfo)
  	   SELECT 	  	 ProductionEventId 	  	 = e.Event_Id,
 	  	  	  	  	 DepartmentName 	  	  	 = pu.Dept_Desc,
 	  	  	  	  	 LineName 	  	  	  	  	 = pu.PL_Desc,
 	  	  	  	  	 UnitName 	  	  	  	  	 = pu.PU_Desc, 
 	  	  	  	  	 EventName 	  	  	  	 = e.Event_Num, 
 	  	  	  	  	 EventType 	  	  	  	 = es.Event_Subtype_Desc,
 	  	  	  	  	 EventStatus 	  	  	  	 = ps.ProdStatus_Desc, 
 	  	  	  	  	 TestingStatus 	  	  	 = 'Unknown',
 	  	  	  	  	 OriginalProduct 	  	 = p1.Prod_Code, 
 	  	  	  	  	 AppliedProduct 	  	  	 = p2.Prod_Code, 
 	  	  	  	  	 ProcessOrder 	  	  	 = po.ProcessOrder,
 	  	  	  	  	 StartTime 	  	  	  	 =  dbo.fnCmn_GetEventStartTime(e.Event_Id) , 
 	  	  	  	  	 EndTime 	  	  	  	 = e.TimeStamp, 
 	  	  	  	  	 InitialDimensionX 	  	 = ed.Initial_Dimension_X, 
 	  	  	  	  	 InitialDimensionY 	  	 = ed.Initial_Dimension_Y, 
 	  	  	  	  	 InitialDimensionZ 	  	 = ed.Initial_Dimension_Z,
 	  	  	  	  	 InitialDimensionA 	  	 = ed.Initial_Dimension_A,
 	  	  	  	  	 FinalDimensionX 	  	 = ed.Final_Dimension_X, 
 	  	  	  	  	 FinalDimensionY 	  	 = ed.Final_Dimension_Y, 
 	  	  	  	  	 FinalDimensionZ 	  	 = ed.Final_Dimension_Z,
 	  	  	  	  	 FinalDimensionA 	  	 = ed.Final_Dimension_A,
 	  	  	  	  	 CommentId 	  	  	  	 = e.Comment_Id,
 	  	  	  	  	 ExtendedInfo 	  	  	 = e.Extended_Info,
                                        SignatureId                    = e.Signature_Id
 	  	  	  	 FROM   	    Events e
 	  	  	  	 INNER JOIN 	 @pus pu 	  	  	  	  	  	 ON 	  	 e.PU_Id = pu.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0
 	  	  	  	 INNER JOIN 	 Event_Configuration ec 	 ON 	  	 e.PU_Id = ec.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ec.ET_Id = 1
 	  	  	  	 INNER JOIN 	 Event_SubTypes es 	  	  	 ON 	  	 ec.Event_SubType_Id = es.Event_SubType_Id
 	  	  	  	 INNER JOIN 	 Production_Status ps 	  	 ON   	 ps.ProdStatus_Id = e.Event_Status
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ps.ProdStatus_Desc LIKE @EventStatus
 	  	  	  	 LEFT JOIN 	 @ProductChanges s 	  	  	 ON 	  	 s.PU_Id = e.pu_id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 s.Start_Time <= e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (s.End_Time > e.TimeStamp OR s.End_Time IS NULL)
 	  	  	  	 INNER JOIN 	 Products p1   	      	    ON 	  	 p1.Prod_Id = s.Prod_Id
 	  	  	  	 LEFT JOIN 	 Products p2 	  	  	  	  	 ON 	  	 p2.Prod_Id = e.Applied_Product
 	  	  	  	 LEFT JOIN 	 @ProcessOrders po 	  	  	 ON 	  	 po.PU_Id = e.pu_id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 po.Start_Time <= e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (po.End_Time > e.TimeStamp OR po.End_Time IS NULL)
 	  	  	  	 LEFT JOIN 	 Event_Details ed 	  	  	 ON 	  	 ed.Event_Id = e.Event_Id
 	  	  	  	 WHERE 	 e.TimeStamp >= @StartTime
 	  	  	  	 AND 	 e.TimeStamp <= @EndTime
 	  	  	  	 AND 	 e.Event_Num 	 LIKE @EventMask
 	  	  	  	 AND 	 ISNULL(p2.Prod_Code, p1.Prod_Code) LIKE @ProductCode
 	  	  	  	 ORDER BY e.Timestamp
/*
SELECT 	 ProductionEventId = Event_Id,
 	  	  	 DepartmentName,
 	  	  	 LineName,
 	  	  	 UnitName,
 	  	  	 EventName,
 	  	  	 EventType,
 	  	  	 EventStatus,
 	  	  	 TestingStatus,
 	  	  	 OriginalProduct,
 	  	  	 AppliedProduct,
 	  	  	 ProcessOrder,
 	  	  	 StartTime,
 	  	  	 EndTime,
 	  	  	 InitialDimensionX = IX,
 	  	  	 InitialDimensionY = IY,
 	  	  	 InitialDimensionZ = IZ,
 	  	  	 InitialDimensionA = IA,
 	  	  	 FinalDimensionX = FX,
 	  	  	 FinalDimensionY = FY,
 	  	  	 FinalDimensionZ = FZ,
 	  	  	 FinalDimensionA = FA,
 	  	  	 CommentId,
 	  	  	 ExtendedInfo
 	  	  	 FROM 	 @EventList e
 	  	  	 WHERE 	 COALESCE(AppliedProduct, OriginalProduct) LIKE @ProductCode
 	  	  	 ORDER BY EndTime ASC
*/
