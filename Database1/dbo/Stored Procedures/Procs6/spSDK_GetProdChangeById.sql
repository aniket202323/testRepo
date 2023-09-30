CREATE PROCEDURE dbo.spSDK_GetProdChangeById
 	 @StartId 	  	  	  	 INT
AS
-- Mask For Name Has Not Been Specified
SELECT 	 ProductChangeId = Start_Id,
 	  	  	 LineName = PL_Desc,
 	  	  	 UnitName = PU_Desc, 
 	  	  	 StartTime = ps.Start_Time, 
 	  	  	 EndTime = ps.End_Time, 
 	  	  	 Confirmed = ps.Confirmed, 
 	  	  	 Event_SubType_Desc = es.Event_SubType_Desc, 
 	  	  	 p.Prod_Code, 
 	  	  	 CommentId = ps.Comment_Id,
            SignatureId = ps.Signature_Id
 	 FROM 	 Prod_Lines pl 	  	  	 JOIN
 	  	  	 Prod_Units pu 	  	  	 ON (pl.PL_Id = pu.PL_Id) JOIN
 	  	  	 Production_Starts ps 	 ON (ps.PU_Id = pu.PU_Id) JOIN
 	  	  	 Products p  	  	  	  	 ON (ps.Prod_Id = p.Prod_Id) LEFT JOIN 
 	  	  	 Event_Subtypes es 	  	 ON (es.Event_SubType_Id = ps.Event_SubType_Id)
 	 WHERE 	 ps.Start_Id = @StartId
