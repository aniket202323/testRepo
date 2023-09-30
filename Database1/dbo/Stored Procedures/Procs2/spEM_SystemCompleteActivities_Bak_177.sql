CREATE PROCEDURE dbo.[spEM_SystemCompleteActivities_Bak_177] @ReturnStatus  INT          = NULL OUTPUT,
                                                   @ReturnMessage nvarchar(255) = NULL OUTPUT,
                                                   @EConfig_Id    INT          = NULL
AS
/*
459 key pair value changed
1   ---- > 0
2   ---- > 2
3   ---- > 1
*/
BEGIN
 	 Declare @IsActivtityOrderSet Bit
    DECLARE @CurrentTime DATETIME= dbo.fnServer_CmnGetDate(GETUTCDATE());
    DECLARE @OldActivities TABLE(Id             INT,
                                 ActivityId     INT,
                                 ActivityTypeId INT)
 	 
 	 DECLARE @Sheet_Id Int,@Value459 INT
    INSERT INTO @OldActivities
    SELECT ROW_NUMBER() OVER(ORDER BY System_Complete_Duration_Time DESC),
           Activity_Id,
           Activity_Type_Id
           FROM Pending_SystemCompleteActivities
           WHERE System_Complete_Duration_Time < @CurrentTime
    DECLARE @SCLoopStart INT= 1, @SCLoopEnd INT= (SELECT MAX(Id) FROM @OldActivities)
    DECLARE @SCActivityId INT, @SCActivityTypeId INT, @SCUserId INT= 5, @SCCommentId INT, @SCComment nVarChar(300);
    WHILE @SCLoopStart <= @SCLoopEnd
        BEGIN
            SELECT @SCActivityId = ActivityId,
                   @SCActivityTypeId = ActivityTypeId FROM @OldActivities WHERE Id = @SCLoopStart
            SET @SCComment = 'System completed the activity '+CAST(@SCActivityId AS nvarchar(20))+' on '+CAST(dbo.fnServer_CmnConvertFromDbTime(@CurrentTime,'UTC') AS nvarchar(30)) + ' (UTC)';
 	  	  	 DECLARE @OldCommentId INT 
 	  	  	 SELECT @OldCommentId = Comment_Id,@Sheet_Id = Sheet_Id FROM Activities WHERE Activity_Id = @SCActivityId;
 	  	  	 Select @Value459  = ISNULL(Value,0) from Sheet_Display_Options where Sheet_id = @Sheet_Id and display_option_Id = 459
 	  	  	 SELECT @IsActivtityOrderSet = CASE WHEN ((Select SUM(Activity_Order) from Sheet_Variables where Sheet_Id = @Sheet_Id ) > 0) AND EXISTS(Select 1 from Sheet_Display_Options where Sheet_Id =@Sheet_Id and Display_Option_Id = 445 and Value =1) THEN 1 ELSE 0 END 	  	 
 	  	  	 IF @Value459 in(1,2) OR @IsActivtityOrderSet = 1
 	  	  	 Begin 
 	  	  	  	 Delete from Pending_SystemCompleteActivities where Activity_Id = @SCActivityId
 	  	  	 End
 	  	  	 Else 
 	  	  	 Begin
 	  	  	  	 /*IF EXISTS(Select 1 from dbo.fnCMN_ActivitiesCompleteTests(@SCActivityId,NULL,NULL,NULL) Where 
 	  	  	  	 (
 	  	  	  	  	 (TotalTests = CompleteTests AND TotalTests > 0)
 	  	  	  	  	 OR
 	  	  	  	  	 (TotalTests = 0)
 	  	  	  	 )) AND */
 	  	  	  	 IF @IsActivtityOrderSet = 0 
 	  	  	  	 Begin
 	  	  	  	  	 INSERT INTO Comments( Comment,
 	  	  	  	  	  	  	  	  	  	   Comment_Text,
 	  	  	  	  	  	  	  	  	  	   User_Id,
 	  	  	  	  	  	  	  	  	  	   Entry_On,
 	  	  	  	  	  	  	  	  	  	   CS_Id,
 	  	  	  	  	  	  	  	  	  	   Modified_On )
 	  	  	  	  	 VALUES(@SCComment, @SCComment, @SCUserId, @CurrentTime, 1, @CurrentTime)
 	  	  	  	  	 SET @SCCommentId = Scope_Identity()
 	  	  	  	  	 UPDATE Comments set TopOfChain_Id = Case when @OldCommentId is not null then @OldCommentId end where comment_Id = @SCCommentId 
 	  	  	  	  	 SET @SCCommentId = Case when @OldCommentId IS NULL THEN @SCCommentId ELSE @OldCommentId END
 	  	  	            
 	  	  	  	  	 EXEC dbo.spServer_DBMgrUpdActivities @SCActivityId, NULL, NULL, @SCCommentId, 3, NULL, NULL, @CurrentTime, @SCActivityTypeId, NULL, NULL, NULL, NULL, NULL, NULL, 2, 0, @SCUserId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, 3
 	  	  	  	 End
 	  	  	  	 --Write else part to log error detail
 	  	  	 End
            SET @SCLoopStart+=1
        END
    SET @ReturnStatus = 1
    SET @ReturnMessage = ''
END
