CREATE PROCEDURE dbo.spSDK_GetInputEventById
 	 @InputEventId 	  	  	 INT
AS
--Mask For Name Has Been Specified
SELECT 	 InputEventId = peie.Input_Event_Id, 
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 InputName = pei.Input_Name, 
 	  	  	 Position = peip.PEIP_Desc, 
 	  	  	 SourceLineName = srcpl.PL_Desc, 
 	  	  	 SourceUnitName = srcpu.PU_Desc, 
 	  	  	 SourceEventName = e.Event_Num, 
 	  	  	 Timestamp = peie.TimeStamp, 
 	  	  	 DimensionX = peie.Dimension_X, 
 	  	  	 DimensionY = peie.Dimension_Y, 
 	  	  	 DimensionZ = peie.Dimension_Z, 
 	  	  	 DimensionA = peie.Dimension_A,
 	  	  	 Unloaded = peie.Unloaded,
 	  	  	 CommentId = peie.Comment_Id
    FROM 	 Prod_Lines pl  	  	  	  	  	  	 JOIN
 	  	  	 Prod_Units pu  	  	  	  	  	  	 ON (pl.PL_Id = pu.PL_Id) JOIN
 	  	  	 PrdExec_Inputs pei  	  	  	  	 ON (pu.PU_Id = pei.PU_Id) LEFT JOIN
 	  	  	 PrdExec_Input_Event peie  	  	 ON (pei.PEI_Id = peie.PEI_Id) JOIN
 	  	  	 PrdExec_Input_Positions peip  	 ON (peie.PEIP_Id = peip.PEIP_Id) LEFT JOIN
 	  	  	 Events e  	  	  	  	  	  	  	 ON (peie.Event_Id = e.Event_Id) LEFT JOIN
 	  	  	 Prod_Units srcpu  	  	  	  	  	 ON (e.PU_Id = srcpu.PU_Id) LEFT JOIN
 	  	  	 Prod_Lines srcpl  	  	  	  	  	 ON (srcpu.PL_Id = srcpl.PL_Id)
 	 WHERE 	 peie.Input_Event_Id = @InputEventId
