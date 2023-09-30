CREATE PROCEDURE [dbo].[spSDK_AU_BOMFamily]
@AppUserId int,
@Id int OUTPUT,
@BOMFamily nvarchar(50) ,
@CommentId int OUTPUT,
@CommentText text ,
@SecurityGroup varchar(100) ,
@SecurityGroupId int 
AS
IF @Id IS NULL
BEGIN
 	 SELECT @Id = BOM_Family_Id 
 	  	 FROM Bill_Of_Material_Family
 	  	 WHERE BOM_Family_Desc = @BOMFamily
 	 If @Id IS NOT NULL
  BEGIN
 	  	 Select 'Failed - Bill Of Material Family already exists'
 	  	 RETURN (-100)
  END
END
ELSE
BEGIN
 	 SELECT @CommentId = COALESCE(Comment_Id,@CommentId),@SecurityGroupId = Group_Id 
 	  	 FROM Bill_Of_Material_Family 
 	  	 WHERE BOM_Family_Id = @Id
END
EXECUTE spEM_BOMSaveFamily 	 @SecurityGroupId,@CommentId,@BOMFamily, 	 @Id OUTPUT
IF @Id IS NULL
BEGIN
 	 SELECT 'Failed - Could not create Bill Of Material Family'
 	 RETURN (-100)
END
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 EXECUTE spEM_DeleteComment @Id,'fk',@AppUserId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	 EXECUTE spEM_CreateComment  @Id,'fk',@AppUserId,1,@CommentId OUTPUT
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText, Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
