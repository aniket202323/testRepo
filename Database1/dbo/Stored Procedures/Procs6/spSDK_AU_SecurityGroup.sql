CREATE procedure [dbo].[spSDK_AU_SecurityGroup]
@AppUserId int,
@Id int OUTPUT,
@CommentId int OUTPUT,
@CommentText text ,
@ExternalInfo nvarchar(255) ,
@SecurityGroup nvarchar(50) 
AS
DECLARE @OldCommentId Int
IF @Id Is Not Null
BEGIN
 	 IF Not Exists(SELECT 1 FROM Security_Groups WHERE Group_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Security Group not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT  @OldCommentId = Comment_Id FROM Security_Groups WHERE Group_Id = @Id
 	 UPDATE Security_Groups Set Group_Desc = @SecurityGroup,External_Link = @ExternalInfo
 	  	 WHERE Group_Id = @Id
END
ELSE
BEGIN
 	 SELECT @Id = Group_Id 	 FROM Security_Groups 	 WHERE Group_Desc = @SecurityGroup
 	 IF @Id Is Null
 	 BEGIN
 	  	 INSERT INTO Security_Groups(Group_Desc,External_Link)
 	  	  	 VALUES(@SecurityGroup,@ExternalInfo)
 	  	 SELECT @Id = Group_Id 	 FROM Security_Groups 	 WHERE Group_Desc = @SecurityGroup
 	 END
 	 ELSE
 	 BEGIN
 	  	  	 SELECT 'Security Group already exists - add failed'
 	  	  	 RETURN(-100)
 	 END
END
SET @CommentId = COALESCE(@OldCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 DELETE FROM Comments WHERE TopOfChain_Id = @CommentId
 	 DELETE FROM Comments WHERE Comment_Id = @CommentId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	  	 INSERT INTO Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 SELECT @CommentText,@CommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 1
    SELECT @CommentId = Scope_Identity()
    UPDATE Security_Groups SET Comment_Id = @CommentId WHERE Group_Id = @Id
END
ELSE
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
