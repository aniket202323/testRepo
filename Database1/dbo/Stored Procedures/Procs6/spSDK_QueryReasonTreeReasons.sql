CREATE PROCEDURE dbo.spSDK_QueryReasonTreeReasons
 	 @TreeMask 	  	  	  	 nvarchar(50) = NULL,
 	 @Level1Reason 	  	  	 nvarchar(100) = NULL,
 	 @Level2Reason 	  	  	 nvarchar(100) = NULL,
 	 @Level3Reason 	  	  	 nvarchar(100) = NULL
AS
SET 	 @TreeMask = REPLACE(COALESCE(@TreeMask, '*'), '*', '%')
SET 	 @TreeMask = REPLACE(REPLACE(@TreeMask, '?', '_'), '[', '[[]')
IF @Level1Reason IS NULL
BEGIN
 	 SELECT 	 ReasonId = er1.Event_Reason_Id,
 	  	  	  	 ReasonName = er1.Event_Reason_Name,
 	  	  	  	 ReasonCode = er1.Event_Reason_Code
 	  	 FROM 	 Event_Reason_Tree ert 	  	  	 JOIN
 	  	  	  	 Event_Reason_Tree_Data ertd1 	 ON (ert.Tree_Name_Id = ertd1.Tree_Name_Id AND ertd1.Event_Reason_Level = 1) JOIN
 	  	  	  	 Event_Reasons er1 	  	  	  	  	 ON (ertd1.Event_Reason_Id = er1.Event_Reason_Id)
 	  	 WHERE 	 ert.Tree_Name LIKE @TreeMask
 	  	 ORDER BY ReasonName
END ELSE
IF @Level2Reason IS NULL
BEGIN
 	 SELECT 	 ReasonId = er2.Event_Reason_Id,
 	  	  	  	 ReasonName = er2.Event_Reason_Name,
 	  	  	  	 ReasonCode = er2.Event_Reason_Code
 	  	 FROM 	 Event_Reason_Tree ert 	  	  	 JOIN
 	  	  	  	 Event_Reason_Tree_Data ertd1 	 ON (ert.Tree_Name_Id = ertd1.Tree_Name_Id AND ertd1.Event_Reason_Level = 1) JOIN
 	  	  	  	 Event_Reason_Tree_Data ertd2 	 ON (ertd1.Event_Reason_Tree_Data_Id = ertd2.Parent_Event_R_Tree_Data_Id) JOIN
 	  	  	  	 Event_Reasons er1  	  	  	  	 ON (ertd1.Event_Reason_Id = er1.Event_Reason_Id) JOIN
 	  	  	  	 Event_Reasons er2  	  	  	  	 ON (ertd2.Event_Reason_Id = er2.Event_Reason_Id)
 	  	 WHERE 	 ert.Tree_Name LIKE @TreeMask AND
 	  	  	  	 er1.Event_Reason_Name = @Level1Reason 
 	  	 ORDER BY ReasonName
END ELSE
IF @Level3Reason IS NULL
BEGIN
 	 SELECT 	 ReasonId = er3.Event_Reason_Id,
 	  	  	  	 ReasonName = er3.Event_Reason_Name,
 	  	  	  	 ReasonCode = er3.Event_Reason_Code
 	  	 FROM 	 Event_Reason_Tree ert 	  	  	 JOIN
 	  	  	  	 Event_Reason_Tree_Data ertd1 	 ON (ert.Tree_Name_Id = ertd1.Tree_Name_Id AND ertd1.Event_Reason_Level = 1) JOIN
 	  	  	  	 Event_Reason_Tree_Data ertd2 	 ON (ertd1.Event_Reason_Tree_Data_Id = ertd2.Parent_Event_R_Tree_Data_Id) JOIN
 	  	  	  	 Event_Reason_Tree_Data ertd3 	 ON (ertd2.Event_Reason_Tree_Data_Id = ertd3.Parent_Event_R_Tree_Data_Id) JOIN
 	  	  	  	 Event_Reasons er1 	  	  	  	  	 ON (ertd1.Event_Reason_Id = er1.Event_Reason_Id) JOIN
 	  	  	  	 Event_Reasons er2 	  	  	  	  	 ON (ertd2.Event_Reason_Id = er2.Event_Reason_Id) JOIN
 	  	  	  	 Event_Reasons er3 	  	  	  	  	 ON (ertd3.Event_Reason_Id = er3.Event_Reason_Id)
 	  	 WHERE 	 ert.Tree_Name LIKE @TreeMask AND
 	  	  	  	 er1.Event_Reason_Name = @Level1Reason AND
 	  	  	  	 er2.Event_Reason_Name = @Level2Reason
 	  	 ORDER BY ReasonName
END ELSE
BEGIN
 	 SELECT 	 ReasonId = er4.Event_Reason_Id,
 	  	  	  	 ReasonName = er4.Event_Reason_Name,
 	  	  	  	 ReasonCode = er4.Event_Reason_Code
 	  	 FROM 	 Event_Reason_Tree ert 	  	  	 JOIN
 	  	  	  	 Event_Reason_Tree_Data ertd1 	 ON (ert.Tree_Name_Id = ertd1.Tree_Name_Id AND ertd1.Event_Reason_Level = 1) JOIN
 	  	  	  	 Event_Reason_Tree_Data ertd2 	 ON (ertd1.Event_Reason_Tree_Data_Id = ertd2.Parent_Event_R_Tree_Data_Id) JOIN
 	  	  	  	 Event_Reason_Tree_Data ertd3 	 ON (ertd2.Event_Reason_Tree_Data_Id = ertd3.Parent_Event_R_Tree_Data_Id) JOIN
 	  	  	  	 Event_Reason_Tree_Data ertd4 	 ON (ertd3.Event_Reason_Tree_Data_Id = ertd4.Parent_Event_R_Tree_Data_Id) JOIN
 	  	  	  	 Event_Reasons er1  	  	  	  	 ON (ertd1.Event_Reason_Id = er1.Event_Reason_Id) JOIN
 	  	  	  	 Event_Reasons er2  	  	  	  	 ON (ertd2.Event_Reason_Id = er2.Event_Reason_Id) JOIN
 	  	  	  	 Event_Reasons er3  	  	  	  	 ON (ertd3.Event_Reason_Id = er3.Event_Reason_Id) JOIN
 	  	  	  	 Event_Reasons er4  	  	  	  	 ON (ertd4.Event_Reason_Id = er4.Event_Reason_Id)
 	  	 WHERE 	 ert.Tree_Name LIKE @TreeMask AND
 	  	  	  	 er1.Event_Reason_Name LIKE @Level1Reason AND
 	  	  	  	 er2.Event_Reason_Name = @Level2Reason AND
 	  	  	  	 er3.Event_Reason_Name = @Level3Reason
 	  	 ORDER BY ReasonName
END
RETURN(0)
