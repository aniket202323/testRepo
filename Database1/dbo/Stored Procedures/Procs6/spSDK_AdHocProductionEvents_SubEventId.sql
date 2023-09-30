CREATE PROCEDURE dbo.spSDK_AdHocProductionEvents_SubEventId
  	  @EventId int
AS 
SELECT 	 ProductionEventId 	 = e.Event_Id,
 	  	 LineName 	  	  	 = pl.PL_Desc,
 	  	 UnitName 	  	  	 = pu.PU_Desc, 
 	  	 EventName 	  	  	 = e.Event_Num, 
 	  	 EventType 	  	  	 = es.Event_Subtype_Desc,
 	  	 EventStatus 	  	 = ps.ProdStatus_Desc, 
 	  	 TestingStatus 	  	 = 'Unknown',
 	  	 OriginalProduct 	 = p1.Prod_Code, 
 	  	 AppliedProduct 	  	 = p2.Prod_Code, 
 	  	 ProcessOrder 	  	 = pp.Process_Order,
 	  	 StartTime 	  	  	 = IsNull(e.Start_Time, e.Timestamp), 
 	  	 EndTime 	  	  	 = e.TimeStamp, 
 	  	 InitialDimensionX 	 = ed.Initial_Dimension_X, 
 	  	 InitialDimensionY 	 = ed.Initial_Dimension_Y, 
 	  	 InitialDimensionZ 	 = ed.Initial_Dimension_Z,
 	  	 InitialDimensionA 	 = ed.Initial_Dimension_A,
 	  	 FinalDimensionX 	 = ed.Final_Dimension_X, 
 	  	 FinalDimensionY 	 = ed.Final_Dimension_Y, 
 	  	 FinalDimensionZ 	 = ed.Final_Dimension_Z,
 	  	 FinalDimensionA 	 = ed.Final_Dimension_A,
 	  	 CommentId 	  	  	 = e.Comment_Id,
 	  	 ExtendedInfo 	  	 = e.Extended_Info,
                SignatureId             = e.Signature_Id
FROM Events e 
 	 INNER JOIN Production_Status ps 	  	 ON 	 ps.ProdStatus_Id = e.Event_Status 
 	 INNER JOIN Production_Starts s 	  	 ON 	 s.PU_Id = e.PU_Id
 	  	  	  	  	  	  	  	  	  	 AND s.Start_Time <= e.TimeStamp
 	  	  	  	  	  	  	  	  	  	 AND (s.End_Time > e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	 OR s.End_Time Is Null) 
 	 INNER JOIN Products p1 	  	  	  	 ON 	 p1.Prod_Id = s.Prod_Id 
 	 LEFT JOIN Products p2 	  	  	  	 ON 	 p2.Prod_Id = e.Applied_Product 
 	 INNER JOIN Prod_Units pu 	  	  	  	 ON 	 pu.pu_id = e.pu_id 
 	 INNER JOIN Prod_Lines pl  	  	  	 ON 	 pl.pl_id = pu.pl_id
 	 INNER JOIN Event_Configuration ec 	  	 ON 	 ec.PU_Id = pu.PU_Id
 	  	    	    	    	    	    	    	  	    	 AND ec.ET_Id = 1
 	 INNER JOIN Event_SubTypes es 	  	  	 ON 	 ec.Event_SubType_Id = es.Event_SubType_Id  	  
 	 LEFT JOIN Production_Plan_Starts pps 	 ON 	 pps.PU_Id = e.PU_Id 
 	  	  	  	  	  	  	  	  	  	 AND pps.Start_Time <= e.TimeStamp
 	  	  	  	  	  	  	  	  	  	 AND (pps.End_Time > e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	 OR pps.End_Time Is Null)
 	 LEFT JOIN Production_Plan pp  	    	    	 ON 	 pps.PP_Id = pp.PP_Id 
 	 LEFT JOIN Event_Details ed 	  	  	 ON 	 ed.Event_Id = e.Event_Id
 	 LEFT JOIN Comments c 	  	  	  	 ON 	 e.Comment_Id = c.Comment_Id
Where e.Event_id = @EventId
