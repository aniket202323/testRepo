CREATE procedure [dbo].[spSDK_AU_Department_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@CommentId int OUTPUT,
@CommentText text ,
@Department varchar(200) ,
@ExtendedInfo varchar(255) ,
@TimeZone varchar(100) 
AS
DECLARE @OldDesc 	  	  	  	  	 Varchar(50),
 	  	  	  	 @CurrentCommentId Int
IF @Id IS Null
BEGIN
 	 SELECT @Id = Dept_Id From Departments_Base WHERE Dept_Desc = @Department
 	 IF @Id Is Not Null
 	 BEGIN
 	  	 SELECT 'Department already exists can not create'
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEM_CreateDepartment @Department,@AppUserId,@Id OUTPUT
 	 IF @Id Is Null
 	 BEGIN
 	  	 SELECT 'Failed to create Department'
 	  	 RETURN(-100)
 	 END
END
SELECT @CurrentCommentId = Comment_Id,@OldDesc = Dept_Desc FROM Departments_Base WHERE Dept_Id = @Id
EXECUTE spEM_PutExtLink @Id,'dz',null,@ExtendedInfo,Null,@AppUserId
UPDATE Departments_Base SET Time_Zone = @TimeZone WHERE Dept_Id = @Id 
IF @OldDesc <> @Department
BEGIN
 	 SELECT 'Changing the description field of aspected equipment is not supported'
 	 RETURN(-100) 	  	  	 
END
SET @CommentId = Coalesce(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 EXECUTE spEM_DeleteComment @Id,'dz',@AppUserId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	 EXECUTE spEM_CreateComment  @Id,'dz',@AppUserId,1,@CommentId Output
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
