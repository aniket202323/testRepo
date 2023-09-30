CREATE PROCEDURE dbo.spActivities_CompleteActivities @ActivityIds VARCHAR(7000),  @UserId INT

AS
BEGIN
	
-- Convert the comma seperated values to Table of Ativity Ids -- Start
	DECLARE @ActivityIdsInput TABLE(ActivityId INT NOT NULL)
	If (@ActivityIds IS NOT NULL)
	 	 Set @ActivityIds = REPLACE(@ActivityIds, ' ', '')
	IF @ActivityIds = '' SET @ActivityIds = Null
	IF @ActivityIds IS NULL
		BEGIN
		 	SELECT Error = 'ERROR: Missing required parameter', Code = 'InvalidData', ErrorType = 'MissingRequiredData', PropertyName1 = 'ActivityIds', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	 		RETURN
		END
	--Split comma seperated string
	DECLARE @xml XML
	SET @xml = cast(('<X>'+replace(@ActivityIds,',','</X><X>')+'</X>') as xml)
	INSERT INTO @ActivityIdsInput (ActivityId) SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
--=================================================================================================
	-- Validation for the List of activity Ids -- Return on first Error
	
	DECLARE @ValidateActivities TABLE(ActivityId INT NOT NULL, PreviousStatusId INT)
	INSERT INTO @ValidateActivities (ActivityId , PreviousStatusId) (SELECT A.Activity_Id, A.Activity_Status FROM  Activities A JOIN @ActivityIdsInput A_IP ON A.Activity_Id =A_IP.ActivityId);
	
	--Find Activities that are not in DB
	DECLARE @InvalidActivityIds VARCHAR(max) = null;
	;WITH S as (SELECT ActivityId FROM @ActivityIdsInput EXCEPT SELECT ActivityId FROM @ValidateActivities)
	SELECT @InvalidActivityIds = COALESCE(@InvalidActivityIds+ ',' + cast(ActivityId as varchar(max)),cast(ActivityId as varchar(max))) FROM  S
	IF(@InvalidActivityIds IS NOT NULL OR @InvalidActivityIds <> '')
	BEGIN
		SELECT Code = 'ErrorCompletingActivity',
	                       Error = 'Invalid Activity Ids present in input',
	                       ErrorType = 'ActivityNotFound',
	                       PropertyName1 = 'Activity Ids',
	                       PropertyName2 = '',
	                       PropertyName3 = '',
	                       PropertyName4 = '',
	                       PropertyValue1 = @InvalidActivityIds,
	                       PropertyValue2 = '',
	                       PropertyValue3 = '',
	                       PropertyValue4 = ''
	                RETURN
	END
	
	-- Check if list has already completed Activities
	DECLARE @AlreadyCompletedActivityIds VARCHAR(max) = null;
	;WITH S as (SELECT ActivityId FROM @ValidateActivities WHERE PreviousStatusId = 3)
	SELECT @AlreadyCompletedActivityIds = COALESCE(@AlreadyCompletedActivityIds+ ', ' + cast(ActivityId as varchar(max)),cast(ActivityId as varchar(max))) from S
	IF(@AlreadyCompletedActivityIds IS NOT NULL OR @AlreadyCompletedActivityIds <> '')
	BEGIN
		SELECT Code = 'ErrorCompletingActivity',
	                       Error = 'Invalid Activity Ids present',
	                       ErrorType = 'ActivityAlreadyCompleted',
	                       PropertyName1 = 'Activity Ids',
	                       PropertyName2 = '',
	                       PropertyName3 = '',
	                       PropertyName4 = '',
	                       PropertyValue1 = @AlreadyCompletedActivityIds,
	                       PropertyValue2 = '',
	                       PropertyValue3 = '',
	                       PropertyValue4 = ''
	                RETURN
	END
	
--===================================================================================================
	--Update the Activities record in bulk

	DECLARE @CompletedStatus INT = 3, 
			@Unlocked INT = 0, 
			@Now DATETIME = dbo.fnserver_CmnConvertToDbTime( DateAdd(millisecond,-DatePart(millisecond,GETUTCDATE()),GETUTCDATE()), 'UTC');
	
	UPDATE A SET Activity_Status = @CompletedStatus, Complete_Type = COALESCE(Complete_Type, 0), End_Time = @Now, Locked = @Unlocked, UserId = @UserId 
		FROM Activities A JOIN @ActivityIdsInput A_IP ON A.Activity_Id = A_IP.ActivityId;
	
	--Update the Pending_SystemCompleteActivities Table as well
	DELETE Pending_SystemCompleteActivities
 	    FROM Pending_SystemCompleteActivities P JOIN @ActivityIdsInput A_IP ON P.Activity_Id = A_IP.ActivityId;

	--Update PercentComplete, Tests_To_Complete and HasAvailableCells if if list has Activities the is not yet started
	DECLARE @NotStartedActivities TABLE(ActivityId INT);
	IF EXISTS ( SELECT ActivityId FROM @ValidateActivities WHERE PreviousStatusId IS NULL OR PreviousStatusId = 1)
	BEGIN
		INSERT INTO @NotStartedActivities SELECT ActivityId FROM @ValidateActivities WHERE PreviousStatusId IS NULL OR PreviousStatusId = 1;
		DECLARE @NotStartedActivityId INT = NULL
		SELECT @NotStartedActivityId = MIN( ActivityId ) FROM @NotStartedActivities;
		WHILE (@NotStartedActivityId IS NOT NULL AND @NotStartedActivityId <> 0)
		BEGIN
			DECLARE  @TotalTests INT, @CompleteTests INT, @HasAvailableCells BIT, @TotalVariables INT,@TotalCompletedVariables INT, @TestsToComplete INT, @PercentComplete FLOAT;
			--Find  the total test, completed tests and HasAvailableCells from the function
			SELECT @TotalTests = TotalTests, @CompleteTests = CompleteTests, @HasAvailableCells = HasAvailableCells
 	  	  		FROM dbo.fnCMN_ActivitiesCompleteTests(@NotStartedActivityId,Null,Null,Null) 
 			-- Calculate the values for Tests_To_Complete and PercentComplete
			SET @TestsToComplete = COALESCE(@TotalVariables - @TotalCompletedVariables,0)
 			SET @PercentComplete = CASE WHEN @TotalVariables = 0 THEN 100
 	  	  	  	  	  	  					ELSE ROUND(cast(@TotalCompletedVariables as float) / cast(@TotalVariables as float),2) * 100
 	  	  	  	  	  	  			END
 			UPDATE Activities
 			 	 SET PercentComplete = @PercentComplete,
 			 	  	  Tests_To_Complete = @TestsToComplete,
 			 	  	  HasAvailableCells = @HasAvailableCells
 			 	 WHERE Activity_Id = @NotStartedActivityId and (ISNULL(PercentComplete, 0) != ISNULL(@PercentComplete, 0) or ISNULL(Tests_To_Complete, 0) != ISNULL(@TestsToComplete, 0) or ISNULL(HasAvailableCells, 0) != ISNULL(@HasAvailableCells, 0));
			--Update the pointers for the loop
			DELETE FROM @NotStartedActivities WHERE ActivityId = @NotStartedActivityId;
			SELECT @NotStartedActivityId = MIN( ActivityId ) FROM @NotStartedActivities;
		END
	END
	                                                                 
--===================================================================================================
	--Send messages about the Updated activities
	DECLARE @UpdateTransactionType INT = 2;
	INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 		SELECT 0, (SELECT ResultSetType = 4,
 	  	  	  	  	 TopicId = 300,
 	  	  	  	  	 MessageKey = A.PU_Id,
 	  	  	  	  	 PUId =  A.PU_Id,
 	  	  	  	  	 EventType= A.Activity_Type_Id ,
 	  	  	  	  	 KeyId=A.KeyId1,
 	  	  	  	  	 KeyTime=A.KeyId,
 	  	  	  	  	 ActivityId= A.Activity_Id,
 	  	  	  	  	 ActivityDesc = A.Activity_Desc ,
 	  	  	  	  	 APriority = A.Activity_Priority ,
 	  	  	  	  	 AStatus = A.Activity_Status ,
 	  	  	  	  	 StartTime= dbo.fnServer_CmnConvertFromDbTime(A.Start_Time ,'UTC'),
 	  	  	  	  	 EndTime = dbo.fnServer_CmnConvertFromDbTime(A.End_Time ,'UTC'),
 	  	  	  	  	 TDuration = A.Target_Duration,
 	  	  	  	  	 Title = A.Title,
 	  	  	  	  	 UserId=A.UserId,
 	  	  	  	  	 EntryOn= dbo.fnServer_CmnConvertFromDbTime(A.EntryOn,'UTC'),
 	  	  	  	  	 TransType=@UpdateTransactionType,
 	  	  	  	  	 PercentComplete = A.PercentComplete,
 	  	  	  	  	 Tag = A.Tag ,
 	  	  	  	  	 ExecutionStartTime = A.Execution_Start_Time,
 	  	  	  	  	 AutoComplete = A.Auto_Complete,
 	  	  	  	  	 ExtendedInfo = A.Extended_Info,
 	  	  	  	  	 ExternalLink = A.External_Link,
 	  	  	  	  	 TestsToComplete = A.Tests_To_Complete,
 	  	  	  	  	 Locked = A.Locked,
 	  	  	  	  	 CommentId = A.Comment_Id, 
 	  	  	  	  	 OverdueCommentId = A.Overdue_Comment_Id,
 	  	  	  	  	 SkipCommentId = A.Skip_Comment_Id,
 	  	  	  	  	 SheetId = A.Sheet_Id,
 	  	  	  	  	 TransNum = 0,
 	  	  	  	  	 LockActivity = A.Lock_Activity_Security,
 	  	  	  	  	 NeedOverdueComment = A.Overdue_Comment_Security
 	  	  	  	 FROM @ActivityIdsInput A_IP
 	  	  	  	 JOIN Activities A ON A_IP.ActivityId  = A. Activity_Id for xml path ('row'), ROOT('rows')), 
 	  	 @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())

	Declare @returnStatus BIT = 1;
	SELECT @returnStatus as 'Status'
END