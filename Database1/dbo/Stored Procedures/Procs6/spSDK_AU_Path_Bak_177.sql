CREATE procedure [dbo].[spSDK_AU_Path_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@CommentId int OUTPUT,
@CommentText text ,
@CreateChildren bit ,
@Department varchar(200) ,
@DepartmentId int ,
@IsLineProduction bit ,
@IsScheduleControlled bit ,
@PathCode varchar(200) ,
@PathDescription varchar(200) ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ScheduleControlTypeId tinyint 
AS
DECLARE @OldCommentId 	  	 Int
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT
IF @Id Is not null
BEGIN
 	 IF Not Exists(SELECT 1 FROM Prdexec_Paths WHERE Path_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Path not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @OldCommentId = Comment_Id
 	  	 FROM Prdexec_Paths
 	  	 WHERE Path_Id = @Id
END
ELSE
BEGIN
 	 IF  Exists(SELECT 1 FROM Prdexec_Paths WHERE Path_Code  = @PathCode and PL_Id = @ProductionLineId)
 	 BEGIN
 	  	 SELECT 'Path Already exists adds not allowed'
 	  	 RETURN(-100)
 	 END
END
SET @CreateChildren = coalesce(@CreateChildren,0)
EXECUTE spEMEPC_PutExecPaths 	 @ProductionLineId,@PathDescription,@PathCode,@IsScheduleControlled,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ScheduleControlTypeId,@IsLineProduction,@CreateChildren,@AppUserId,@Id  OUTPUT
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
    UPDATE Prdexec_Paths SET Comment_Id = @CommentId WHERE Path_Id = @Id
END
ELSE
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
