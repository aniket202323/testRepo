CREATE PROCEDURE dbo.spSDK_QueryProductionEvents_SubEventNum
   	 @EventMask   	 nvarchar(50) 	  	  	 = NULL,
   	 @UserId 	  	  	 INT 	  	  	  	  	     = NULL
as
/*
dbo.spSDK_QueryProductionEvents_SubEventNum 'P15Z0249',1
select * from events where event_num = 'P15Z0249'
select top 5 event_Num, * from events where pu_id = 2 order by timestamp desc 
*/
SELECT 	  	 ProductionEventId 	  	 = e.Event_Id,
 	  	  	  	  	 DepartmentName 	  	  	 = d.Dept_Desc,
 	  	  	  	  	 LineName 	  	  	  	  	 = pl.PL_Desc,
 	  	  	  	  	 UnitName 	  	  	  	  	 = pu.PU_Desc, 
 	  	  	  	  	 EventName 	  	  	  	 = e.Event_Num, 
 	  	  	  	  	 EventType 	  	  	  	 = es.Event_Subtype_Desc,
 	  	  	  	  	 EventStatus 	  	  	  	 = ps.ProdStatus_Desc, 
 	  	  	  	  	 TestingStatus 	  	  	 = 'Unknown',
 	  	  	  	  	 OriginalProduct 	  	 = p1.Prod_Code, 
 	  	  	  	  	 AppliedProduct 	  	  	 = p2.Prod_Code, 
 	  	  	  	  	 ProcessOrder 	  	  	 = pp.Process_Order,
 	  	  	  	  	 StartTime 	  	  	  	 = IsNull(e.Start_Time, e.TimeStamp),
 	  	  	  	  	 EndTime 	  	  	  	  	 = e.TimeStamp, 
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
 	  	  	  	  	 SignatureId             = e.Signature_Id
 	  	  	  	 FROM   	    Events e
 	  	  	  	 JOIN 	 Prod_Units pu 	  	 ON pu.PU_Id = e.PU_Id 
 	  	  	  	 JOIN  Prod_Lines pl  	 ON pl.PL_Id = pu.PL_Id
 	  	  	  	 JOIN 	 Departments d 	  	 ON d.Dept_Id = pl.Dept_Id
 	  	  	  	 JOIN 	 Event_Configuration ec 	 ON 	  	 e.PU_Id = ec.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ec.ET_Id = 1
 	  	  	  	 JOIN 	 Event_SubTypes es 	  	  	 ON 	  	 ec.Event_SubType_Id = es.Event_SubType_Id
 	  	  	  	 JOIN 	 Production_Status ps 	  	 ON   	 ps.ProdStatus_Id = e.Event_Status
 	  	  	  	 JOIN 	 Production_Starts s 	  	  	 ON 	  	 s.PU_Id = e.pu_id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 s.Start_Time <= e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (s.End_Time > e.TimeStamp OR s.End_Time IS NULL)
 	  	  	  	 JOIN 	 Products p1   	      	    ON 	  	 p1.Prod_Id = s.Prod_Id
 	  	  	  	 LEFT JOIN 	 Products p2 	  	  	  	  	 ON 	  	 p2.Prod_Id = e.Applied_Product
 	  	     LEFT JOIN Production_Plan_Starts pps ON pps.PU_Id = e.PU_Id
                               	  	 and pps.Start_Time < e.Timestamp
                               	  	 AND 	 (pps.End_Time > e.Timestamp OR 	 pps.End_Time IS NULL)
 	  	     LEFT JOIN Production_Plan pp 	 ON pp.pp_id = pps.pp_id 
 	  	  	  	 LEFT JOIN 	 Event_Details ed 	  	  	 ON 	  	 ed.Event_Id = e.Event_Id
 	  	  	  	 LEFT JOIN 	 User_Security pls 	 ON 	  	 pl.Group_id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	  	  	  	 LEFT JOIN 	 User_Security pus 	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId
 	  	  	  	 WHERE 	 e.Event_Num 	 = @EventMask
 	  	  	  	  	 AND 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
-- 	  	  	  	 ORDER BY e.Timestamp
