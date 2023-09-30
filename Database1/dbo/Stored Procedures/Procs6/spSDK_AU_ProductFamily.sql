CREATE procedure [dbo].[spSDK_AU_ProductFamily]
@AppUserId int,
@Id int OUTPUT,
@CommentId int OUTPUT,
@CommentText text ,
@ExternalInfo nvarchar(255) ,
@ProductFamily nvarchar(50) ,
@SecurityGroup varchar(100) ,
@SecurityGroupId int 
AS
DECLARE @CurrentCommentId 	 Int,
 	  	  	  	 @OldDesc 	  	  	  	  	 VarChar(50)
IF @Id is Not Null
BEGIN
 	 SELECT @OldDesc = a.Product_Family_Desc ,@CurrentCommentId = Comment_Id
 	  	 FROM Product_Family  a
 	  	 WHERE  a.Product_Family_Id = @Id
 	 IF @OldDesc <> @ProductFamily
 	 BEGIN
 	  	 EXECUTE spEM_RenameProductFamily @Id,@ProductFamily,@AppUserId
 	 END
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Product_Family WHERE Product_Family_Desc = @ProductFamily)
 	 BEGIN
 	  	 SELECT 'Product Family Already Exists'
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEM_CreateProductFamily @ProductFamily,@AppUserId,@Id OUTPUT
 	 IF @Id is null
 	 BEGIN
 	  	 SELECT 'Unable to Create Product Family'
 	  	 RETURN(-100)
 	 END
END
EXECUTE spEM_PutExtLink @Id,'cn',@ExternalInfo,Null,Null,@AppUserId
EXECUTE spEM_PutSecurityProdFamily @Id,@SecurityGroupId,@AppUserId
SET @CommentId = Coalesce(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 EXECUTE spEM_DeleteComment @Id,'cn',@AppUserId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	 EXECUTE spEM_CreateComment  @Id,'cn',@AppUserId,1,@CommentId Output
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
