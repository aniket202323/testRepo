CREATE PROCEDURE dbo.spBF_GetReasonTreeData
  @TransactionNum Int,
  @TransType Int,
  @Id Int,
  @PId int
  AS
/*
@TransactionNum
1 - Reason
2 - ReasonTree
3 - Reason+Tree
4 - ReasonTree + Category
5 - Reason + Unit
6 - ReasonTreeLevelHeaders
*/
Declare @Level int
IF @TransactionNum Not In (1,2,3,4,5,6)
BEGIN
 	 SELECT Error = 'Error: Invalid Transaction Number'
 	 Return
END
IF @TransactionNum = 1 ----Reasons
BEGIN
 	 IF @Id is Null -- All Reasons
 	 BEGIN
 	  	 SELECT ReasonId = Event_Reason_Id,
 	  	  	 ReasonDescription = 	 Event_Reason_Name  
 	  	 FROM Event_Reasons 
 	  	 ORDER By Event_Reason_Name
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF @TransType = 1 --On Tree
 	  	   IF @PId is null
 	  	     BEGIN
 	  	  	 SELECT @Level = 1
 	  	  	 SELECT  TreeDataId = a.Event_Reason_Tree_Data_Id,
 	  	  	  	     ReasonId = a.Event_Reason_Id,
 	  	  	  	  	 ReasonDescription = Event_Reason_Name,
 	  	  	  	  	 CategoryDataId = c.ERCD_Id, 
 	  	  	  	  	 CategoryDescription =  d.ERC_Desc
 	  	  	  	 FROM Event_Reason_Tree_Data a
 	  	  	  	 JOIN Event_Reasons b on a.Event_Reason_Id =  b.Event_Reason_Id
 	  	  	  	 Left Join Event_Reason_Category_Data c On c.Event_Reason_Tree_Data_Id = a.Event_Reason_Tree_Data_Id 
 	  	  	  	 Left Join Event_Reason_Catagories d on d.ERC_Id = c.ERC_Id 
 	  	  	  	 WHERE a.Tree_Name_Id = @id and a.Event_Reason_Level = @Level and a.Parent_Event_R_Tree_Data_Id Is Null
 	  	  	  	 Order BY Event_Reason_Name
 	  	  	 END
 	  	   ELSE
 	  	     BEGIN
 	  	  	 select @Level = Event_Reason_Level + 1 from Event_Reason_Tree_Data where event_reason_tree_data_id = @PId
 	  	  	 SELECT  TreeDataId = a.Event_Reason_Tree_Data_Id,
 	  	  	  	     ReasonId = a.Event_Reason_Id,
 	  	  	  	  	 ReasonDescription = Event_Reason_Name,
 	  	  	  	  	 CategoryDataId = c.ERCD_Id, 
 	  	  	  	  	 CategoryDescription =  d.ERC_Desc
 	  	  	  	 FROM Event_Reason_Tree_Data a
 	  	  	  	 JOIN Event_Reasons b on a.Event_Reason_Id =  b.Event_Reason_Id
 	  	  	  	 Left Join Event_Reason_Category_Data c On c.Event_Reason_Tree_Data_Id = a.Event_Reason_Tree_Data_Id 
 	  	  	  	 Left Join Event_Reason_Catagories d on d.ERC_Id = c.ERC_Id 
 	  	  	  	 WHERE a.Tree_Name_Id = @id and a.Event_Reason_Level = @Level and a.Parent_Event_R_Tree_Data_Id = @PId
 	  	  	  	 Order BY Event_Reason_Name
 	  	  	 END
 	  	 IF @TransType = 2 --Not On Tree
 	  	   IF @PId is null
 	  	     BEGIN
 	  	  	 SELECT @Level = 1
 	  	  	 SELECT ReasonId = a.Event_Reason_Id,
 	  	  	        ReasonDescription = 	 Event_Reason_Name  
 	  	  	  	 FROM Event_Reasons a
 	  	  	  	 LEFT JOIN Event_Reason_Tree_Data b on a.Event_Reason_Id =  b.Event_Reason_Id And b.Tree_Name_Id = @id and b.Event_Reason_Level = @Level and b.Parent_Event_R_Tree_Data_Id Is Null
 	  	  	  	 WHERE  b.Event_Reason_Tree_Data_Id Is Null
 	  	  	  	 Order BY Event_Reason_Name
 	  	  	 END
 	  	   ELSE
 	  	     BEGIN
 	  	  	 select @Level = Event_Reason_Level + 1 from Event_Reason_Tree_Data where event_reason_tree_data_id = @PId
 	  	  	 SELECT ReasonId = a.Event_Reason_Id,
 	  	  	        ReasonDescription = 	 Event_Reason_Name  
 	  	  	  	 FROM Event_Reasons a
 	  	  	  	 LEFT JOIN Event_Reason_Tree_Data b on a.Event_Reason_Id =  b.Event_Reason_Id And b.Tree_Name_Id = @id and b.Event_Reason_Level = @Level and b.Parent_Event_R_Tree_Data_Id = @PId
 	  	  	  	 WHERE  b.Event_Reason_Tree_Data_Id Is Null
 	  	  	  	 Order BY Event_Reason_Name
 	  	  	 END
 	 END
END
ELSE IF @TransactionNum = 2 ----Reason Trees
BEGIN
 	 SELECT TreeId = Tree_Name_Id,TreeDescription = Tree_Name 
 	 FROM Event_Reason_Tree
 	 ORDER BY Tree_Name
END
ELSE IF @TransactionNum = 4 ----Categories
BEGIN
 	 IF @Id Is Null
 	 BEGIN
 	  	 SELECT CategoryId = ERC_Id,CategoryDescription = ERC_Desc 
 	  	    FROM Event_Reason_Catagories
 	  	    WHERE ERC_Id in (1,3,6)
 	  	    ORDER BY ERC_Desc
 	 END
END
ELSE IF @TransactionNum = 5 -- Attach Tree to Unit
BEGIN
 	 SELECT TreeId = a.Name_Id,TreeDescription = c.Tree_Name 
 	  	 FROM Prod_Events a 
 	  	 JOIN Prod_Units b On a.PU_Id   = b.PU_Id
 	  	 JOIN Event_Reason_Tree  c on c.Tree_Name_Id = a.Name_Id
 	  	 WHERE a.PU_Id = @Id and a.Event_Type = 2
END
ELSE IF @TransactionNum = 6 -- Reason Tree Level Headers
BEGIN
 	 SELECT EventReasonLevelHeaderId = a.Event_Reason_Level_Header_Id, LevelName = a.Level_Name, ReasonLevel = a.Reason_Level 
 	  	 FROM Event_Reason_Level_Headers a 
 	  	 WHERE a.Tree_Name_Id = @Id
END
