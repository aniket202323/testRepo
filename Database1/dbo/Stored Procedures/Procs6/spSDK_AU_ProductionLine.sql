CREATE procedure [dbo].[spSDK_AU_ProductionLine]
@AppUserId int,
@Id int OUTPUT,
@CommentId int OUTPUT,
@CommentText text ,
@Department varchar(200) ,
@DepartmentId int ,
@ExtendedInfo varchar(255) ,
@ExternalLink varchar(100) ,
@ProductionLine nvarchar(50) ,
@SecurityGroup varchar(100) ,
@SecurityGroupId int ,
@Tag varchar(100) ,
@UserDefined1 varchar(100) ,
@UserDefined2 varchar(100) ,
@UserDefined3 varchar(100) 
AS
DECLARE @OldDesc 	  	  	  	  	 Varchar(50),
 	  	  	  	 @CurrentCommentId Int
/*
Not supported in Administratr so not supported here
@Tag
@UserDefined1
@UserDefined2
@UserDefined3
*/ 	  	  	  	 
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @Id
IF @Id IS Null
BEGIN
 	 IF @DepartmentId Is Null
 	 BEGIN
 	  	 SELECT 'Department is required to create a line'
 	  	 RETURN(-100)
 	 END
 	 SELECT @Id = PL_Id From Prod_Lines_Base  WHERE PL_Desc = @ProductionLine
 	 IF @Id Is Not Null
 	 BEGIN
 	  	 SELECT 'Production Line already exists can not create'
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEM_CreateProdLine @ProductionLine,@DepartmentId,@AppUserId,@Id OUTPUT
 	 IF @Id Is Null
 	 BEGIN
 	  	 SELECT 'Failed to create Production Line'
 	  	 RETURN(-100)
 	 END
END
SELECT @CurrentCommentId = Comment_Id,@OldDesc = PL_Desc
 	 FROM Prod_Lines_Base
 	 WHERE PL_Id = @Id
 	 
EXECUTE spEM_PutExtLink @Id,'ad',@ExternalLink,@ExtendedInfo,Null,@AppUserId
IF @OldDesc <> @ProductionLine
BEGIN
 	  	 SELECT 'Changing the description field of equipment is not supported'
 	  	 RETURN(-100) 	  	  	 
END
EXECUTE spEM_PutSecurityLine @Id,@SecurityGroupId,@AppUserId
SET @CommentId = Coalesce(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 EXECUTE spEM_DeleteComment @Id,'ad',@AppUserId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	 EXECUTE spEM_CreateComment  @Id,'ad',@AppUserId,1,@CommentId Output
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
RETURN(1)
