CREATE PROCEDURE dbo.spBF_ManageReasonTrees
  @id Int,
  @Description  nvarchar(50),
  @Code nvarchar(25),
  @TransactionNum Int,  
  @TransactionType Int = 0,
  @Id2 Int,
  @EventReasonDataIdParent int,
  @UserId Int = 1
  AS
/*
@TransactionNum
1 - Reason
2 - ReasonTree
3 - Reason+Tree
4 - ReasonTree + Category
5 - Reason + Unit
6 - EventReasonLevelHeaders
*/
/*
@TransactionType
1 - Add
2 - Update
3 - Delete
*/
DECLARE @OldDesc nVarChar(100)
DECLARE @OldCode nVarChar(100)
DECLARE @NewId Int
Declare @LevelId int
SELECT @Description = ltrim(rtrim(@Description))
SELECT @Code = ltrim(rtrim(@Code))
IF @TransactionNum Not In (1,2,3,4,5,6)
BEGIN
 	 SELECT Error = 'Error: Invalid Transaction Number'
 	 Return
END
IF @TransactionType Not In (1,2,3)
BEGIN
 	 SELECT Error = 'Error: Invalid Transaction Type'
 	 Return
END
IF @TransactionType  = 1 and @Description Is Null and @TransactionNum  In (1,2,6)
BEGIN
 	 SELECT Error = 'Error: Description Required For Add'
 	 Return
END
IF @TransactionType  in(2,3) and @Id Is Null
BEGIN
 	 SELECT Error = 'Error: Id Required For Update And Delete'
 	 Return
END
IF @TransactionType  in (1) and @TransactionNum  In (3,4,5) and @Id2 Is Null
BEGIN
 	 SELECT Error = 'Error: Id Required For Update And Delete'
 	 Return
END
IF @TransactionNum = 1 ----Reasons
BEGIN
 	 IF @TransactionType = 1  -- Add
 	 BEGIN
 	  	 IF EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Name = @Description)
 	  	 BEGIN
 	  	  	 SELECT Error = 'Error: Reason Name Not Unique'
 	  	  	 RETURN
 	  	 END
 	  	 EXECUTE spEM_CreateEventReason  @Description,@Code, 0,@UserId,@id OUTPUT
 	 END
 	 ELSE IF @TransactionType = 2  -- Update
 	 BEGIN
 	  	 SELECT @OldCode  = Event_Reason_Code,@OldDesc = Event_Reason_Name FROM Event_Reasons WHERE Event_Reason_Id = @id
 	  	 SELECT @Description = coalesce(@Description,@OldDesc)
 	  	 SELECT @Code = coalesce(@Code,@OldCode)
 	  	 IF @OldDesc <> @Description
 	  	 BEGIN
 	  	  	 If Exists(Select 1 FROM Event_Reasons WHERE Event_Reason_Name = @Description)
 	  	  	 BEGIN
 	  	  	  	 SELECT Error = 'Error: Reason Already Exists'
 	  	  	  	 RETURN
 	  	  	 END
 	  	 END
 	  	 EXECUTE dbo.spEM_UpdateEventReason  @id,@Description,@Code,0,@UserId
 	 END
 	 ELSE -- DELETE
 	 BEGIN
 	  	 SELECT Error = 'Error: Reason Delete Not Supported'
 	  	 Return
 	 END
 	 SELECT Event_Reason_Id,Event_Reason_Name  FROM Event_Reasons WHERE Event_Reason_Id = @id
END
ELSE IF @TransactionNum = 2 ----Reason Trees
BEGIN
 	 IF @TransactionType = 1  -- Add
 	 BEGIN
 	  	 IF EXISTS(SELECT 1 FROM Event_Reason_Tree WHERE  Tree_Name = @Description)
 	  	 BEGIN
 	  	  	 SELECT Error = 'Error: Tree Name Not Unique'
 	  	  	 RETURN
 	  	 END
 	  	 EXECUTE dbo.spEM_CreateReasonTreeName  @Description,@UserId,@id OUTPUT
 	 END
 	 ELSE IF @TransactionType = 2  -- Update
 	 BEGIN
 	  	 SELECT @OldDesc = Tree_Name FROM Event_Reason_Tree WHERE Tree_Name_Id = @id
 	  	 SELECT @Description = coalesce(@Description,@OldDesc)
 	  	 IF @OldDesc <> @Description
 	  	 BEGIN
 	  	  	 If Exists(Select 1 FROM Event_Reason_Tree WHERE Tree_Name = @Description)
 	  	  	 BEGIN
 	  	  	  	 SELECT Error = 'Error: Reason Tree Already Exists'
 	  	  	  	 RETURN
 	  	  	 END
 	  	 END
 	  	 EXECUTE dbo.spEM_RenameReasonTree  @id,@Description,@UserId
 	 END
 	 ELSE IF @TransactionType = 3  -- DELETE
 	 BEGIN
 	  	 EXECUTE spEM_DropReasonTree @id,@UserId
 	  	 SELECT 'Success'
 	  	 Return
 	 END
 	 SELECT Tree_Name_Id,Tree_Name FROM Event_Reason_Tree WHERE Tree_Name_Id = @Id
END
ELSE IF @TransactionNum = 3 ----Reason To Trees
BEGIN
 	 IF @TransactionType = 1  -- Add 
 	 BEGIN
 	  	 IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree WHERE Tree_Name_Id = @Id)
 	  	 BEGIN
 	  	  	 SELECT Error = 'Error: Reason Tree Id Not Found'
 	  	  	 RETURN
 	  	 END
 	  	 IF NOT EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Id = @Id2)
 	  	 BEGIN
 	  	  	 SELECT Error = 'Error: Reason Id Not Found'
 	  	  	 RETURN
 	  	 END
 	  	 if @EventReasonDataIdParent is null
 	  	   begin
 	  	  	 select @LevelId = 1
 	  	   end
 	  	 else
 	  	   begin
 	  	  	 select @LevelId = Event_Reason_Level + 1 from Event_Reason_Tree_Data where event_reason_tree_data_id = @EventReasonDataIdParent
 	  	   end
 	  	 EXECUTE dbo.spEM_CreateEventReasonData  @Id,@Id2,@EventReasonDataIdParent,@LevelId,@UserId,@NewId OUTPUT
 	 END
 	 ELSE IF @TransactionType = 2  -- Update
 	 BEGIN
 	  	 SELECT Error = 'Error: Update Not supported'
 	  	 RETURN
 	 END
 	 ELSE IF @TransactionType = 3  -- DELETE
 	 BEGIN
 	  	 EXECUTE dbo.spEM_DropEventReasonTreeData @id,@UserId
 	  	 SELECT 'Success'
 	  	 Return
 	 END
 	 SELECT Event_Reason_Tree_Data_Id,b.Event_Reason_Name 
 	  	 FROM Event_Reason_Tree_Data a 
 	  	 JOIN Event_Reasons b On a.Event_Reason_Id = b.Event_Reason_Id
 	  	 WHERE Event_Reason_Tree_Data_Id = @NewId
END
ELSE IF @TransactionNum = 4 ----Attach Caregories
BEGIN
 	 IF @TransactionType = 1  -- Add 
 	 BEGIN
 	  	 EXECUTE dbo.spEM_CreateCategoryMember  @Id,@Id2,@UserId,@NewId OUTPUT   --  @Id = ERTDID ---- @Id2 = @ERC_Id
 	 END
 	 ELSE IF @TransactionType = 2  -- Update
 	 BEGIN
 	  	 SELECT Error = 'Error: Update Not supported'
 	  	 RETURN
 	 END
 	 ELSE IF @TransactionType = 3  -- DELETE
 	 BEGIN
 	  	 EXECUTE dbo.spEM_DropCategoryData @id,@UserId
 	  	 SELECT 'Success'
 	  	 Return
 	 END
 	 SELECT a.ERCD_Id,b.ERC_Desc,d.Event_Reason_Name 
 	  	 FROM Event_Reason_Category_Data a 
 	  	 JOIN Event_Reason_Catagories b On a.ERC_Id  = b.ERC_Id
 	  	 Join Event_Reason_Tree_Data c on c.Event_Reason_Tree_Data_Id = a.Event_Reason_Tree_Data_Id
 	  	 JOIN Event_Reasons d On d.Event_Reason_Id = c.Event_Reason_Id
 	  	 WHERE a.ERCD_Id  = @NewId
END
ELSE IF @TransactionNum = 5 -- Attach Tree to Unit
BEGIN
 	 IF @TransactionType in ( 1,2)
 	 BEGIN
 	  	 EXECUTE spEM_PutProdEvents  @Id2,@Id,2,@UserId
 	 END
 	 ELSE IF @TransactionType = 3  -- DELETE
 	 BEGIN
 	  	 EXECUTE spEM_PutProdEvents @Id,Null,2,@UserId
 	  	 SELECT 'Success'
 	  	 Return
 	 END
 	 SELECT a.PU_Id,a.Name_Id,b.PU_Desc,c.Tree_Name 
 	  	 FROM Prod_Events a 
 	  	 JOIN Prod_Units b On a.PU_Id   = b.PU_Id
 	  	 JOIN Event_Reason_Tree  c on c.Tree_Name_Id = a.Name_Id
 	  	 WHERE a.PU_Id = @Id2 and a.Name_Id = @Id
END
ELSE IF @TransactionNum = 6 -- EventReasonLevelHeaders
BEGIN
 	 IF @TransactionType = 1
 	 BEGIN
 	  	 EXECUTE spEM_CreateReasonTreeHeader @Id2, @Description, @UserId, @Id output
 	 END
 	 ELSE IF @TransactionType = 2  -- UPDATE
 	 BEGIN
 	  	 EXECUTE dbo.spEM_RenameReasonTreeHeader @Id, @Description, @UserId
 	 END
 	 ELSE IF @TransactionType = 3  -- DELETE
 	 BEGIN
 	  	 EXECUTE spEM_DropReasonTreeHeader @Id, @UserId
 	  	 SELECT 'Success'
 	  	 Return
 	 END
 	 SELECT a.Event_Reason_Level_Header_Id, a.Level_Name, a.Reason_Level, a.Tree_Name_Id
 	  	 FROM Event_Reason_Level_Headers a 
 	  	 WHERE a.Event_Reason_Level_Header_Id = @Id
END
