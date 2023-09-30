CREATE PROCEDURE [dbo].[spBF_GetNPTData]
  @ItemId 	 Int,
  @TreeId 	 Int,
  @TransNum Int
  AS
/*
@TransNum 
1 - Return Unit List of Trees For a Line
2 - Return List of Units For Line/Tree 
3 - Return List of Units in the Group
4-  Return Unit List of Trees For a Unit
*/
IF @TransNum   Not In (1,2,3,4)
BEGIN
 	 SELECT Error = 'Error: Invalid Transaction Number'
 	 RETURN 	 
END
IF @TransNum   In (1,2,3,4)
BEGIN
 	 IF @ItemId Is Null
 	 BEGIN
 	  	 SELECT Error = 'Error: Item Id is Required'
 	  	 RETURN 	 
 	 END 	 
END
IF @TransNum = 1
BEGIN
 	 SELECT DISTINCT TreeId = b.Non_Productive_Reason_Tree,c.Tree_Name   
 	  	 FROM Prod_Lines a
 	  	 JOIN prod_Units b ON b.PL_Id = a.PL_Id 
 	  	 JOIN Event_Reason_Tree c on c.Tree_Name_Id = b.Non_Productive_Reason_Tree
 	  	 WHERE a.PL_Id = @ItemId
END
IF @TransNum = 2
BEGIN
 	 IF @TreeId  Is Null
 	 BEGIN
 	  	 SELECT Error = 'Error: Event Reason Tree Not Found'
 	  	 RETURN 	 
 	 END 	 
 	 SELECT DISTINCT PUId = PU_Id,PUDesc = PU_Desc  
 	  	 FROM prod_Units a 
 	  	 WHERE a.PL_Id = @ItemId and a.Non_Productive_Reason_Tree = @TreeId
END
IF @TransNum = 3
BEGIN
  SELECT DISTINCT b.PU_Id,b.PU_Desc 
    FROM NonProductive_Detail a
    JOIN prod_Units b ON b.PU_Id = a.PU_Id 
    WHERE NPT_Group_Id = @ItemId
END 
IF @TransNum = 4
BEGIN
 	 SELECT DISTINCT TreeId = b.Non_Productive_Reason_Tree,c.Tree_Name   
 	  	 FROM prod_Units b 
 	  	 JOIN Event_Reason_Tree c on c.Tree_Name_Id = b.Non_Productive_Reason_Tree
 	  	 WHERE b.PU_Id = @ItemId
END
