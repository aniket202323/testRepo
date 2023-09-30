CREATE PROCEDURE dbo.spServer_DBMgrAutoCompleteActivities @PUId           INT,
                                                          @SheetId        INT,
                                                          @ActivityTypeId INT,
                                                          @StartTime      DATETIME
AS
/* ##### spServer_DBMgrUpdActivities #####
Description 	 :  Auto complete previous activities
Creation Date 	 : 2018/05/17
Created By 	 : Krishna
#### Update History ####
DATE 	  	  	  Modified By 	  	 UserStory/Defect No 	  	 Comments 	 
---- 	  	  	  ----------- 	  	 ------------------- 	  	 --------
459 key pair value changed
1   ---- > 0
2   ---- > 2
3   ---- > 1
*/
BEGIN
Declare @IsActivtityOrderSet Bit
SELECT @IsActivtityOrderSet = CASE WHEN ((Select SUM(Activity_Order) from Sheet_Variables where Sheet_Id = @SheetId ) > 0) AND EXISTS(Select 1 from Sheet_Display_Options where Sheet_Id =@SheetId and Display_Option_Id = 445 and Value =1) THEN 1 ELSE 0 END
    IF EXISTS(SELECT 1 FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId
                                                        AND Display_Option_Id = 459
                                                        AND Value > 0 AND @IsActivtityOrderSet = 0)--for value 1 and 2 only we need to auto complete
        BEGIN
  	    	    	   --TODO: check for old activities and complete them
            DECLARE @OldActivities TABLE(Id             INT,
                                         ActivityId     INT,
                                         ActivityTypeId INT,
                                         ProdId         INT,Comment_Id INT)
            DECLARE @Prod_Id INT, @Prod_Code nVarChar(100), @Start_Id INT, @Time DATETIME
            EXEC dbo.spActivities_GetRunningGrade @PUId, @StartTime, 0, @Prod_Id OUTPUT, @Prod_Code OUTPUT, @Start_Id OUTPUT, @Time OUTPUT
            INSERT INTO @OldActivities
            SELECT ROW_NUMBER() OVER(ORDER BY KeyId DESC),
                   A.Activity_Id,
                   A.Activity_Type_Id,
                   PS.Prod_Id, A.Comment_Id
                   FROM(SELECT Activity_Id,
                               Activity_Type_Id,
                               KeyId,
                               Pu_Id,Comment_Id
                               FROM Activities AS A
                               WHERE A.Activity_Status IN(1, 2)
                        AND A.Sheet_Id = @SheetId
                        AND A.Activity_Type_Id = @ActivityTypeId
                        AND A.KeyId <= @StartTime) AS A
                       INNER JOIN Production_Starts AS PS ON PS.PU_Id = A.PU_Id
                                                             AND PS.Prod_Id = @Prod_Id
                                                             AND PS.Start_Time <= A.KeyId
                                                             AND (PS.End_Time IS NULL
                                                                  OR PS.End_Time >= A.KeyId)
                       LEFT JOIN Production_Plan_Starts AS PPS ON PPS.PU_Id = A.PU_Id
                                                                  AND PPS.Start_Time <= A.KeyId
                                                                  AND (PPS.End_Time >= A.KeyId
                                                                       OR PPS.End_Time IS NULL)
  	    	    -- AC: Auto Complete
 	  	    ;WITH S As (
 	  	     Select A.ActivityId, Case when TotalTests = Completetests then 1 else 0 end IsCompleted from @OldActivities A cross apply dbo.fnCMN_ActivitiesCompleteTests(ActivityId,NULL,NULL,NULL)
 	  	  	 )
 	  	  	 ,S1 As (Select ActivityId From S Where IsCompleted = 0 And EXISTS(SELECT 1 FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId AND Display_Option_Id = 459 AND Value = 2))
 	  	  	 Delete from @OldActivities Where ActivityId in (Select ActivityId from S1)
 	  	    
 	  	  	 DECLARE @ACLoopStart INT= 1, @ACLoopEnd INT= (SELECT MAX(Id) FROM @OldActivities)
            DECLARE @ACActivityId INT, @ACActivityTypeId INT, @ACSheetId INT, @ACTimeStamp DATETIME, @ACProdId INT, @ACUserId INT= 5, @ACCommentId INT, @ACComment VARCHAR(300);
 	  	  	 DECLARE @ACOldCommentId INT
  	    	    SET @ACTimeStamp = dbo.fnServer_CmnGetDate(GETUTCDATE());
 	  	    -- Loop through all the old activities and complete them 	  	    
            WHILE @ACLoopStart <= @ACLoopEnd
                BEGIN
                    SELECT @ACActivityId = ActivityId,
                           @ACActivityTypeId = ActivityTypeId,@ACOldCommentId= Comment_Id,
                           @ACProdId = ProdId FROM @OldActivities WHERE Id = @ACLoopStart
                    SET @ACComment = 'System completed the activity '+CAST(@ACActivityId AS nVarChar(20))+' on '+CAST(dbo.fnServer_CmnConvertFromDbTime(@ACTimeStamp,'UTC') AS nvarchar(30)) + ' (UTC)'+' when the new activity was created';
  	    	    	    	  -- Insert a new comment and get comment Id
                    INSERT INTO Comments( Comment,
                                          Comment_Text,
                                          User_Id,
                                          Entry_On,
                                          CS_Id,
                                          Modified_On )
                    VALUES(@ACComment, @ACComment, @ACUserId, @ACTimeStamp, 1, @ACTimeStamp)
                    SET @ACCommentId = Scope_Identity()
 	  	  	  	  	 
 	  	  	  	  	 UPDATE Comments set TopOfChain_Id = Case when @ACOldCommentId is not null then @ACOldCommentId end where comment_Id = @ACCommentId 
 	  	  	  	     SET @ACCommentId = Case when @ACOldCommentId IS NULL THEN @ACCommentId ELSE @ACOldCommentId END
 	  	  	 
  	    	    	    	  --Update the activity using recursion
                    EXEC dbo.spServer_DBMgrUpdActivities @ACActivityId, NULL, NULL, @ACCommentId, 3, NULL, NULL, @ACTimeStamp, @ACActivityTypeId, NULL, NULL, NULL, NULL, NULL, NULL, 2, 0, @ACUserId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, 2
                    SET @ACLoopStart+=1
                END
        END
END
