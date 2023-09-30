CREATE procedure [dbo].[spSDK_AU_VariableGroup_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@CommentId int OUTPUT,
@CommentText text ,
@Department varchar(200) ,
@DepartmentId int ,
@ExternalInfo nvarchar(255) ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int ,
@SecurityGroup varchar(100) ,
@SecurityGroupId int ,
@VarableGroupOrder int ,
@VariableGroup nvarchar(50) 
AS
DECLARE @CurrentCommentId 	 Int,
 	  	  	  	 @OldDesc 	  	  	  	  	 VarChar(50),
 	  	  	  	 @NewVarableGroupOrder Int
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId OUTPUT,
 	  	  	  	 @VariableGroup OUTPUT,
 	  	  	  	 @Id 
/* @@VarableGroupOrder not supported (need to sync all groups if changed) */
IF @Id is Not Null
BEGIN
 	 SELECT @OldDesc = Pug_Desc,@CurrentCommentId = Comment_Id 
 	  	 FROM PU_Groups   a
 	  	 WHERE Pug_Id = @Id and a.Pu_Id = @ProductionUnitId
 	 IF @OldDesc <> @VariableGroup
 	 BEGIN
 	  	 EXECUTE spEM_RenamePUG @Id,@VariableGroup,@AppUserId
 	 END
END
ELSE
BEGIN
 	 SELECT @NewVarableGroupOrder = MAX(PUG_Order) FROM PU_Groups WHERE PU_Id = @ProductionUnitId
 	 SET @NewVarableGroupOrder = Coalesce(@VarableGroupOrder,0) + 1
 	 EXECUTE spEM_CreatePUG @VariableGroup,@ProductionUnitId,@VarableGroupOrder,@AppUserId,@Id OUTPUT
 	 IF @Id is null
 	 BEGIN
 	  	 SELECT 'Unable to Create Variable Group'
 	  	 RETURN(-100)
 	 END
END
EXECUTE spEM_OrderGroup @Id,@VarableGroupOrder,@AppUserId 
EXECUTE spEM_PutExtLink @Id,'af',@ExternalInfo,Null,Null,@AppUserId
SET @CommentId = Coalesce(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 EXECUTE spEM_DeleteComment @Id,'af',@AppUserId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	 EXECUTE spEM_CreateComment  @Id,'af',@AppUserId,1,@CommentId Output
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
