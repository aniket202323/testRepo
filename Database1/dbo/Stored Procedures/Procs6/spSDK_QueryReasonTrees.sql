CREATE PROCEDURE dbo.spSDK_QueryReasonTrees
 	 @TreeMask 	  	  	  	 nvarchar(50) = NULL
AS
SET 	 @TreeMask = REPLACE(COALESCE(@TreeMask, '*'), '*', '%')
SET 	 @TreeMask = REPLACE(REPLACE(@TreeMask, '?', '_'), '[', '[[]')
SELECT 	 ReasonTreeId = r.Tree_Name_Id,
 	  	  	 TreeName = r.Tree_Name,
 	  	  	 Level1Name = h1.Level_Name,
 	  	  	 Level2Name = h2.Level_Name,
 	  	  	 Level3Name = h3.Level_Name,
 	  	  	 Level4Name = h4.Level_Name
 	 FROM 	 Event_Reason_Tree r LEFT JOIN
 	  	  	 Event_Reason_Level_Headers h1 ON (r.Tree_Name_Id = h1.Tree_Name_Id AND h1.Reason_Level = 1) LEFT JOIN
 	  	  	 Event_Reason_Level_Headers h2 ON (r.Tree_Name_Id = h2.Tree_Name_Id AND h2.Reason_Level = 2) LEFT JOIN
 	  	  	 Event_Reason_Level_Headers h3 ON (r.Tree_Name_Id = h3.Tree_Name_Id AND h3.Reason_Level = 3) LEFT JOIN
 	  	  	 Event_Reason_Level_Headers h4 ON (r.Tree_Name_Id = h4.Tree_Name_Id AND h4.Reason_Level = 4)
 	 WHERE 	 r.Tree_Name LIKE @TreeMask
