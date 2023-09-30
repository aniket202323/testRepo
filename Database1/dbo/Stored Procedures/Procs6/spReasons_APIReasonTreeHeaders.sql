
CREATE PROCEDURE [dbo].[spReasons_APIReasonTreeHeaders]
@Id                nvarchar(max), 
@TreeType 	  	  	  	 Int = 1,
@EventType               Int = 2
AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/


 	 IF @TreeType = 1
 	 BEGIN
 	  	 SELECT erlh.Event_Reason_Level_Header_Id
 	  	   ,erlh.Reason_Level
 	  	   ,erlh.Tree_Name_Id
 	  	   ,erlh.Level_Name as 'Level_Name_Global'
 	  	   ,erlh.Level_Name as 'Level_Name_Local'
 	  	   ,erlh.Level_Name FROM Prod_Units pu
 	  	  JOIN Prod_Events pe ON ( pe.PU_Id = pu.PU_Id and pe.Event_Type = @EventType ) 
 	  	  JOIN Event_Reason_Level_Headers erlh ON pe.Name_Id = erlh.Tree_Name_Id
 	  	  WHERE pu.pu_id = @Id
 	 END
 	 ELSE IF @TreeType = 2
 	 BEGIN
 	  	  SELECT erlh.Event_Reason_Level_Header_Id
 	  	   ,erlh.Reason_Level
 	  	   ,erlh.Tree_Name_Id
 	  	   ,erlh.Level_Name as 'Level_Name_Global'
 	  	   ,erlh.Level_Name as 'Level_Name_Local'
 	  	   ,erlh.Level_Name FROM Prod_Units pu
 	  	  JOIN Prod_Events pe ON ( pe.PU_Id = pu.PU_Id and pe.Event_Type = @EventType ) 
 	  	  JOIN Event_Reason_Level_Headers erlh ON pe.Action_Tree_Id = erlh.Tree_Name_Id
 	  	  WHERE pu.pu_id = @Id 
 	 END 	 
 	 ELSE IF @TreeType = 3
 	 BEGIN
 	  	 SELECT erlh.Event_Reason_Level_Header_Id
 	  	   ,erlh.Reason_Level
 	  	   ,erlh.Tree_Name_Id
 	  	   ,erlh.Level_Name as 'Level_Name_Global'
 	  	   ,erlh.Level_Name as 'Level_Name_Local'
 	  	   ,erlh.Level_Name FROM Prod_Units pu
 	  	   JOIN Event_Reason_Level_Headers erlh ON pu.Non_Productive_Reason_Tree = erlh.Tree_Name_Id
 	  	   WHERE pu.pu_id = @Id 
 	 END
 	 ELSE IF @TreeType = 4
 	 BEGIN
 	  	 SELECT Event_Reason_Level_Header_Id, Reason_Level,
 	  	 Tree_Name_Id, Level_Name as 'Level_Name_Global', Level_Name as 'Level_Name_Local', Level_Name 
 	  	 FROM Event_Reason_Level_Headers WHERE Tree_Name_Id = @Id
 	 END
