CREATE PROCEDURE dbo.spSDK_QueryProductionEvents_SubUnitStatus
   	 @LineMask 	  	  	 nvarchar(50) 	  	  	 = NULL,
   	 @UnitMask 	  	  	 nvarchar(50) 	  	  	 = NULL,
   	 @EventStatus   	 nvarchar(50) 	  	  	 = NULL,
   	 @UserId 	  	  	 INT 	  	  	  	  	     = NULL
as
Declare 
  @PUId int, 
  @EventStatusId int, 
  @Dept nvarchar(100)
SELECT 	 @PUId = pu.PU_Id, @Dept = Dept_Desc
 	  	 FROM 	 Prod_Lines pl
 	  	 JOIN 	 Departments d 	 ON 	 d.Dept_Id = pl.Dept_Id
 	  	 JOIN 	 Prod_Units pu 	  	 ON 	  	 pu.PL_Id = pl.PL_Id 
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc = @UnitMask
 	  	 LEFT JOIN 	 User_Security pls 	 ON 	  	 pl.Group_id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	  	 LEFT JOIN 	 User_Security pus 	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId
 	  	 WHERE 	 pl.PL_Desc = @LineMask 
 	  	 AND 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
--Get the ID & Set the case correctly too
SELECT @EventStatusId = ProdStatus_Id, @EventStatus = ProdStatus_Desc
  FROM Production_Status 
  WHERE ProdStatus_Desc = @EventStatus
-- Get Process Orders Between Time Range
--INSERT INTO #ProcessOrders (PU_Id, ProcessOrder, Start_Time, End_Time)
/*
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
*/
DECLARE @EventList TABLE (
 	  	  	  	 ProductionEventId   	      	    INT,
 	  	  	  	 PUId   	      	    INT,
 	  	  	  	 DepartmentName   	    nvarchar(50),
 	  	  	  	 LineName   	      	    nvarchar(50),
 	  	  	  	 UnitName   	      	    nvarchar(50),
 	  	  	  	 EventName   	      	    nvarchar(50),
 	  	  	  	 EventType   	      	    nvarchar(50),
 	  	  	  	 EventStatus 	  	  	  	 nvarchar(50),
 	  	  	  	 TestingStatus   	      	 nvarchar(50),
 	  	  	  	 AppliedProduct 	  	  	 nvarchar(50),
 	  	  	  	 StartTime   	      	    DATETIME,
 	  	  	  	 EndTime   	      	      	 DATETIME,
 	  	  	  	 InitialDimensionX 	  REAL,
 	  	  	  	 InitialDimensionY 	  REAL, 	  	 
 	  	  	  	 InitialDimensionZ 	  REAL, 	  	 
 	  	  	  	 InitialDimensionA 	  REAL, 	  	 
 	  	  	  	 FinalDimensionX 	  REAL, 	  	 
 	  	  	  	 FinalDimensionY 	  REAL, 	  	 
 	  	  	  	 FinalDimensionZ 	  REAL, 	  	 
 	  	  	  	 FinalDimensionA 	  REAL, 	  	 
 	  	  	  	 CommentId   	      	    INT,
 	  	  	  	 ExtendedInfo   	      	 nvarchar(255),
 	  	  	  	 SignatureId 	  	 Int
  	  	 )
INSERT INTO @EventList 
  	  	    	   (ProductionEventId 
          ,PUId
  	  	    	   ,DepartmentName
  	  	    	   ,LineName
  	  	    	   ,UnitName
  	  	    	   ,EventName
  	  	    	   ,EventType
  	  	    	   ,EventStatus
  	  	    	   ,TestingStatus
  	  	    	   ,AppliedProduct
  	  	    	   ,StartTime
  	  	    	   ,EndTime
 	  	  	  	  	 ,InitialDimensionX 	  	 
 	  	  	  	  	 ,InitialDimensionY 	  	 
 	  	  	  	  	 ,InitialDimensionZ 	  	 
 	  	  	  	  	 ,InitialDimensionA 	  	 
 	  	  	  	  	 ,FinalDimensionX 	  	 
 	  	  	  	  	 ,FinalDimensionY 	  	 
 	  	  	  	  	 ,FinalDimensionZ 	  	 
 	  	  	  	  	 ,FinalDimensionA 	  	 
  	  	    	   ,CommentId
  	  	    	   ,ExtendedInfo
 	  	  	   ,SignatureId)
  SELECT 	 e.Event_Id,
          e.PU_Id,
 	  	  	  	  	 DepartmentName 	  	  	 = @Dept,
 	  	  	  	  	 LineName 	  	  	  	  	 = @LineMask,
 	  	  	  	  	 UnitName 	  	  	  	  	 = @UnitMask, 
 	  	  	  	  	 EventName 	  	  	  	 = e.Event_Num, 
 	  	  	  	  	 EventType 	  	  	  	 = es.Event_Subtype_Desc,
 	  	  	  	  	 EventStatus 	  	  	  	 = @EventStatus, 
 	  	  	  	  	 TestingStatus 	  	  	 = 'Unknown',
 	  	  	  	  	 AppliedProduct 	  	  	 = p2.Prod_Code, 
 	  	  	  	  	 StartTime 	  	  	  	 = IsNull(e.Start_Time, e.TimeStamp),
 	  	  	  	  	 EndTime 	  	  	  	  	 = e.TimeStamp
 	  	  	  	  	 ,InitialDimensionX 	  	 = ed.Initial_Dimension_X 
 	  	  	  	  	 ,InitialDimensionY 	  	 = ed.Initial_Dimension_Y 
 	  	  	  	  	 ,InitialDimensionZ 	  	 = ed.Initial_Dimension_Z
 	  	  	  	  	 ,InitialDimensionA 	  	 = ed.Initial_Dimension_A
 	  	  	  	  	 ,FinalDimensionX 	  	 = ed.Final_Dimension_X 
 	  	  	  	  	 ,FinalDimensionY 	  	 = ed.Final_Dimension_Y 
 	  	  	  	  	 ,FinalDimensionZ 	  	 = ed.Final_Dimension_Z
 	  	  	  	  	 ,FinalDimensionA 	  	 = ed.Final_Dimension_A
 	  	  	  	  	 ,CommentId 	  	  	  	 = e.Comment_Id
 	  	  	  	  	 ,ExtendedInfo 	  	  	 = e.Extended_Info
                    ,SignatureId                    = e.Signature_Id
 	  	  	  	 FROM   	    Events e
 	  	  	  	 INNER JOIN 	 Event_Configuration ec 	 ON 	  	 e.PU_Id = ec.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ec.ET_Id = 1
 	  	  	  	 INNER JOIN 	 Event_SubTypes es 	  	  	 ON 	  	 ec.Event_SubType_Id = es.Event_SubType_Id
 	  	  	  	 LEFT JOIN 	 Event_Details ed 	  	  	 ON 	  	 ed.Event_Id = e.Event_Id
 	  	  	  	 LEFT JOIN 	 Products p2 	  	  	  	  	 ON 	  	 p2.Prod_Id = e.Applied_Product
 	  	  	  	 WHERE 	 e.PU_ID = @PUId AND e.Event_Status = @EventStatusId
  SELECT 	 ProductionEventId 	  	 
 	  	  	  	  	 ,DepartmentName 	  	 
 	  	  	  	  	 ,LineName 	  	  	  	  	 
 	  	  	  	  	 ,UnitName 	  	  	  	  	 
 	  	  	  	  	 ,EventName 	  	  	  	 
 	  	  	  	  	 ,EventType 	  	  	  	 
 	  	  	  	  	 ,EventStatus 	  	  	 
 	  	  	  	  	 ,TestingStatus 	  	 
 	  	  	  	  	 ,OriginalProduct 	  	 = p1.Prod_Code 
 	  	  	  	  	 ,AppliedProduct
 	  	  	  	  	 ,ProcessOrder 	  	  	 = pp.Process_Order
 	  	  	  	  	 ,StartTime
 	  	  	  	  	 ,EndTime
 	  	  	  	  	 ,InitialDimensionX 	 
 	  	  	  	  	 ,InitialDimensionY 	 
 	  	  	  	  	 ,InitialDimensionZ 	 
 	  	  	  	  	 ,InitialDimensionA 	 
 	  	  	  	  	 ,FinalDimensionX 	  	 
 	  	  	  	  	 ,FinalDimensionY 	  	 
 	  	  	  	  	 ,FinalDimensionZ 	  	 
 	  	  	  	  	 ,FinalDimensionA 	  	 
 	  	  	  	  	 ,CommentId 	  	  	  	 
 	  	  	  	  	 ,ExtendedInfo
 	  	  	  	  	 ,SignatureId 	  	 
 	  	  	  	 FROM   	    @EventList e
 	  	  	  	 INNER JOIN 	 Production_Starts s 	  	  	 ON 	  	 s.PU_Id = e.PUid 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 s.Start_Time <= e.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (s.End_Time > e.EndTime OR s.End_Time IS NULL)
 	  	  	  	 INNER JOIN 	 Products p1   	      	    ON 	  	 p1.Prod_Id = s.Prod_Id
 	  	     LEFT JOIN Production_Plan_Starts pps ON pps.PU_Id = e.PUId
                               	  	 and pps.Start_Time < e.EndTime
                               	  	 AND 	 (pps.End_Time > e.EndTime OR 	 pps.End_Time IS NULL)
 	  	     LEFT JOIN Production_Plan pp 	 ON pp.pp_id = pps.pp_id 
 	  	  	  	 ORDER BY e.EndTime
