CREATE PROCEDURE dbo.spSDK_ProcessProductChange
 	 @StartId 	  	  	  	 INT
AS
DECLARE 	 @ProdId 	  	 INT,
 	  	  	 @ProdCode 	 nvarchar(100),
 	  	  	 @StartTime 	 DATETIME,
 	  	  	 @EndTime 	  	 DATETIME,
 	  	  	 @UnitId 	  	 INT,
 	  	  	 @LineId 	  	 INT
SELECT 	 @ProdId = Prod_Id, 
 	  	  	 @StartTime = Start_Time, 
 	  	  	 @EndTime = End_Time, 
 	  	  	 @UnitId = PU_id
  	 FROM 	 Production_Starts 
  	 WHERE 	 Start_Id = @StartId
SELECT 	 @ProdCode = Prod_Code 
 	 FROM 	 Products 
 	 WHERE 	 Prod_id = @ProdId
IF @EndTime IS NULL AND @UnitId IS NOT NULL 
BEGIN
 	 SELECT 	 @EndTime = DATEADD(DAY,100,dbo.fnServer_CmnGetDate(getUTCdate()))
END
CREATE TABLE #ProcessOrders (
 	 PU_Id 	  	  	  	 INT,
 	 ProcessOrder 	 nvarchar(50),
 	 Start_Time 	  	 DATETIME,
 	 End_Time 	  	  	 DATETIME NULL
)
CREATE INDEX ProcOrder ON #ProcessOrders (PU_Id, Start_Time)
-- Get Process Orders Between Time Range
INSERT INTO #ProcessOrders (PU_Id, ProcessOrder, Start_Time, End_Time)
 	 SELECT 	 ps.PU_Id, pp.Process_Order, ps.Start_Time, ps.End_Time
 	  	 FROM 	 Production_Plan_Starts ps JOIN 
 	  	  	  	 Production_Plan pp ON pp.pp_id = ps.pp_id 
 	  	 WHERE 	 ps.PU_id = @UnitId and
 	  	  	  	 ps.Start_Time >= @StartTime and 
 	  	  	  	 ps.Start_Time < @EndTime
SELECT 	 ProductionEventId = e.Event_Id,
 	  	  	 LineName = pl.PL_Desc,
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 EventName = e.Event_Num, 
 	  	  	 EventType = es.Event_Subtype_Desc, 
 	  	  	 EventStatus = ps.ProdStatus_Desc, 
 	  	  	 TestingStatus = 'Unknown',
 	  	  	 OriginalProduct = @ProdCode, 
 	  	  	 AppliedProduct = p.Prod_Code, 
 	  	  	 ProcessOrder = po.ProcessOrder,
 	  	  	 StartTime = e.Timestamp, 
 	  	  	 EndTime = e.TimeStamp, 
 	  	  	 Dimension_X = ed.Final_Dimension_X, 
 	  	  	 Dimension_Y = ed.Final_Dimension_Y, 
 	  	  	 Dimension_Z = ed.Final_Dimension_Z,
 	  	  	 Dimension_A = ed.Final_Dimension_A,
 	  	  	 CommentId = e.Comment_Id
  FROM 	 Events e 	  	  	  	  	  	 JOIN
 	  	  	 Prod_Units pu 	  	  	  	 ON e.PU_Id = pu.PU_Id JOIN
 	  	  	 Prod_Lines pl 	  	  	  	 ON pu.PL_Id = pu.PL_Id JOIN
 	  	  	 Event_Configuration ec 	 ON e.PU_Id = ec.PU_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	 ec.ET_Id = 1 JOIN
 	  	  	 Event_SubTypes es 	  	  	 ON ec.Event_Subtype_Id = es.Event_Subtype_Id JOIN
 	  	  	 Production_Status ps  	 ON ps.ProdStatus_Id = e.Event_Status LEFT JOIN 
 	  	  	 Products p 	  	  	  	  	 ON p.Prod_Id = e.Applied_Product LEFT JOIN
 	  	  	 Event_Details ed 	  	  	 ON ed.Event_Id = e.Event_Id LEFT JOIN
 	  	  	 #ProcessOrders po 	  	  	 ON po.PU_Id = e.pu_id AND 
 	  	  	  	  	  	  	  	  	  	  	  	 po.Start_Time <= e.TimeStamp AND 
 	  	  	  	  	  	  	  	  	  	  	  	 ((po.End_Time > e.TimeStamp) OR (po.End_Time Is Null)) LEFT JOIN 
 	  	  	 Comments c 	  	  	  	  	 ON c.Comment_Id = e.Comment_Id
  WHERE 	 e.PU_Id = @UnitId AND
 	  	  	 e.TimeStamp >= @StartTime AND 
 	  	  	 e.TimeStamp < @EndTime      
DROP TABLE #ProcessOrders
