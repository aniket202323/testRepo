CREATE PROCEDURE [dbo].[spSDK_AU_BOM_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@BOM nvarchar(50) ,
@BOMFamily nvarchar(50) ,
@BOMFamilyId int ,
@CommentId int OUTPUT,
@CommentText text ,
@IsActive bit ,
@SecurityGroup varchar(100) ,
@SecurityGroupId int 
AS
IF @Id IS Not NULL
BEGIN
 	 SELECT @CommentId = COALESCE(Comment_Id,@CommentId),@SecurityGroupId = Group_Id 
 	  	 FROM Bill_Of_Material
 	  	 WHERE BOM_Id = @Id
END
EXECUTE spEM_BOMSave @BOMFamilyId,@IsActive,@SecurityGroupId,@CommentId,@BOM,@Id OUTPUT
IF @Id IS NULL
BEGIN
 	 SELECT 'Failed - Could not create Bill Of Material'
 	 RETURN (-100)
END
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 EXECUTE spEM_DeleteComment @Id,'fm',@AppUserId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	 EXECUTE spEM_CreateComment  @Id,'fm',@AppUserId,1,@CommentId OUTPUT
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText, Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN (1)
