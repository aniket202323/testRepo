CREATE PROCEDURE dbo.spSDK_GetWasteById
 	 @WEDId 	  	  	  	 INT
AS
SELECT 	 WasteEventId = WED_Id,
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 WasteType = wet.WET_Name,
 	  	  	 WasteFault = wef.WEFault_Name, 
 	  	  	 SourceLineName = spl.PL_Desc, 
 	  	  	 SourceUnitName = spu.PU_Desc, 
 	  	  	 EventName = Event_Num, 
 	  	  	 Timestamp = wed.Timestamp, 
 	  	  	 Measurement = wem.WEMT_Name, 
 	  	  	 Amount = wed.Amount,
 	  	  	 Cause1 = rl1.Event_Reason_Name, Cause2 = rl2.Event_Reason_Name,
 	  	  	 Cause3 = rl3.Event_Reason_Name, Cause4 = rl4.Event_Reason_Name,
 	  	  	 CauseCommentId = wed.Cause_Comment_Id,
 	  	  	 Action1 = al1.Event_Reason_Name, Action2 = al2.Event_Reason_Name,
 	  	  	 Action3 = al3.Event_Reason_Name, Action4 = al4.Event_Reason_Name,
 	  	  	 ActionCommentId = wed.Action_Comment_Id,
 	  	  	 ResearchOpenDate = wed.Research_Open_Date, 
 	  	  	 ResearchCloseDate = wed.Research_Close_Date,
 	  	  	 ResearchStatus = rs.Research_Status_Desc, ResearchUser = ru.UserName,
 	  	  	 ResearchCommentId = wed.Research_Comment_Id,
 	  	  	 UserGeneral1 = wed.user_General_1,
 	  	  	 UserGeneral2 = wed.user_General_2,
 	  	  	 UserGeneral3 = wed.user_General_3,
 	  	  	 UserGeneral4 = wed.user_General_4,
 	  	  	 UserGeneral5 = wed.user_General_5,
 	  	  	 SignatureId = wed.Signature_Id
 	 FROM 	 Prod_Lines pl  	  	  	  	 JOIN
 	  	  	 Prod_Units pu 	  	  	  	 ON (pl.PL_Id = pu.PL_Id) JOIN
 	  	  	 Waste_Event_Details wed 	  	 ON (pu.PU_Id = wed.PU_Id) LEFT JOIN
 	  	  	 Waste_Event_Type wet 	  	 ON (wed.WET_Id = wet.WET_Id) LEFT JOIN
 	  	  	 Waste_Event_Meas wem 	  	 ON (wed.WEMT_Id = wem.WEMT_Id) LEFT JOIN
 	  	  	 Waste_Event_Fault wef 	  	 ON 	 wef.WEFault_Id = wed.WEFault_Id 	  LEFT JOIN
 	  	  	 Prod_Units spu 	  	  	  	 ON (wed.Source_PU_Id = spu.PU_Id) LEFT JOIN
 	  	  	 Prod_Lines spl 	  	  	  	 ON (spu.PL_Id = spl.PL_Id) LEFT JOIN
 	  	  	 Users u 	  	  	  	  	  	 ON (wed.User_Id = u.User_id) LEFT JOIN
 	  	  	 Events e 	  	  	  	  	  	 ON (wed.Event_Id = e.Event_Id) LEFT JOIN
 	  	  	 Event_Reasons rl1 	  	  	 ON (wed.Reason_Level1 = rl1.Event_Reason_Id) LEFT JOIN
 	  	  	 Event_Reasons rl2 	  	  	 ON (wed.Reason_Level2 = rl2.Event_Reason_Id) LEFT JOIN
 	  	  	 Event_Reasons rl3 	  	  	 ON (wed.Reason_Level3 = rl3.Event_Reason_Id) LEFT JOIN
 	  	  	 Event_Reasons rl4 	  	  	 ON (wed.Reason_Level4 = rl4.Event_Reason_Id) LEFT JOIN
 	  	  	 Event_Reasons al1 	  	  	 ON (wed.Action_Level1 = al1.Event_Reason_Id) LEFT JOIN
 	  	  	 Event_Reasons al2 	  	  	 ON (wed.Action_Level2 = al2.Event_Reason_Id) LEFT JOIN
 	  	  	 Event_Reasons al3 	  	  	 ON (wed.Action_Level3 = al3.Event_Reason_Id) LEFT JOIN
 	  	  	 Event_Reasons al4 	  	  	 ON (wed.Action_Level4 = al4.Event_Reason_Id) LEFT JOIN
 	  	  	 Research_Status rs 	  	 ON (wed.Research_Status_Id = rs.Research_Status_Id) LEFT JOIN
 	  	  	 Users ru 	  	  	  	  	  	 ON (wed.Research_User_Id = ru.User_Id) 
 	 WHERE wed.WED_Id = @WEDId
