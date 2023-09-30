CREATE procedure [dbo].[spSDK_AU_Reason]
@AppUserId int,
@Id int OUTPUT,
@CommentId int OUTPUT,
@CommentRequired tinyint ,
@CommentText text ,
@EventReasonOrder int ,
@ExternalInfo nvarchar(255) ,
@GroupId int ,
@Reason varchar(100) ,
@ReasonCode varchar(10) 
AS
DECLARE
 	 @OldEventReasonName VarChar(100),
 	 @GroupDesc 	  	  	  	  	 VarChar(100),
 	 @CurrentComment 	  	  	 Int
 	 
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
SELECT @GroupDesc = Group_Desc FROM Security_Groups WHERE  Group_Id = @GroupId
SELECT @CommentRequired = COALESCE(@CommentRequired,0)
IF @Id Is Not Null
BEGIN
 	 IF NOT EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Event Reason not found for Update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @OldEventReasonName = a.Event_Reason_Name,
 	  	  	  	  @CurrentComment 	 = a.Comment_Id 
 	 FROM Event_Reasons a
 	 WHERE a.Event_Reason_Id = @Id
END
ELSE
BEGIN
 	 IF EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Name = @Reason)
 	 BEGIN
 	  	 SELECT 'Event Reason already exists - add failed'
 	  	 RETURN(-100)
 	 END
 	 SET @OldEventReasonName = @Reason
END
 	  	 
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportEventReasons 	 
 	  	  	  	  	  	  	  	  	  	 @OldEventReasonName,
 	  	  	  	  	  	  	  	  	  	 @Reason,
 	  	  	  	  	  	  	  	  	  	 @CommentRequired,
 	  	  	  	  	  	  	  	  	  	 @ReasonCode,
 	  	  	  	  	  	  	  	  	  	 @GroupDesc,
 	  	  	  	  	  	  	  	  	  	 @ExternalInfo,
 	  	  	  	  	  	  	  	  	  	 @AppUserId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF @Id IS NULL
 	  	 BEGIN
 	  	  	 SELECT @Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @Reason
 	  	 END
 	  	 SET @CommentId = COALESCE(@CurrentComment,@CommentId)
 	  	 IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
 	  	 BEGIN
 	  	  	 EXECUTE spEM_DeleteComment @Id,'by',@AppUserId
 	  	  	 SET @CommentId = NULL
 	  	 END
 	  	 IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
 	  	 BEGIN
 	  	  	 EXECUTE spEM_CreateComment  @Id,'by',@AppUserId,1,@CommentId Output
 	  	  	 SET @CurrentComment = @CommentId
 	  	 END
 	  	 IF @CommentId IS NOT NULL -- UPDATE TEXT
 	  	 BEGIN
 	  	  	 UPDATE Comments SET Comment = @CommentText, Comment_Text = @CommentText WHERE Comment_Id = @CommentId
 	  	 END
 	 END
 	 RETURN(1)
