
CREATE PROCEDURE [dbo].[spLocal_SA_SkipPreviousActivity]

	/*
	--------------------------------------------------------------------------------------------------------
	Stored procedure		: spLocal_SA_SkipPreviousActivity
	Author					: Steven Stier (Stier Automation LLC)
	Description 			: Automatically Skips previous activity when the next activity is generated based on Auto Skip
							Display option and if on the state of the activty and Blocked status. Manually updates Activity.
							- FO-05418
	Inputs					: JSON Object for for events  with fields EventSubTypeId PUId and EndTime
	Date created			: 03/01/2023  
	Called by				: Called by other SPs typically those that create the UDE.
	Editor tab spacing		: 4
	--------------------------------------------------------------------------------------------------------
	Revision 		Date					Who										What
	========		===========		==================		=================================================================================
	1.0				03/01/2023		Steven Stier			Release for Testing (with Json)  - FO-05418 and FO-05443

	---------------------------------------------------------------------------------------------------------------------------------------------
	Test calls:
  Exec dbo.spLocal_SA_SkipPreviousActivity  [{"EventSubTypeId":121,"PUId":612,"EndTime":"2023-02-27T14:00:01"}]

	--Stier Test Unit 2 Test UDE and Alt Test UDE
	  Exec dbo.spLocal_SA_SkipPreviousActivity  [{"EventSubTypeId":121,"PUId":612,"EndTime":"2023-02-27T13:00:01"}]
	Select * from dbo.Local_SA_Debug where DebugSP = 'spLocal_SA_SkipPreviousActivity' 
  and DebugInputs Like  '%EventSubTypeId":121,"PUId":612%'  order by DebugId desc
	
	--Stier Test Unit 2 RTT Manual
	Select * from dbo.Local_SA_Debug where DebugSP = 'spLocal_SA_SkipPreviousActivity' 
  and DebugInputs Like  '%EventSubTypeId":45,"PUId":612%'  order by DebugId desc

	*/
	@Eventsjson nvarchar(max)
	
	AS 
	SET NOCOUNT ON

	DECLARE 
		@CurrentTime				datetime,
		@RSUserId					int,
		@AutoSkipDisplayOptionId int,
		@Exectime int
	
	DECLARE @Events Table
	(
		EventSubTypeId int,
		PUId int,
		EndTime datetime
	)

	DECLARE @Activities Table  
		(  
			PKey					int IDENTITY(1, 1),  
			SheetID					int,  
			AutoSkipOption 			int,  
			HasActivities			int,  
			PreviousActivityExecutionStartTime					datetime,   
			PreviousActivityStatusID					int,   
			PreviousActivityLocked			int,  
			PreviousActivityID				int,
			SkipCommentId  int,
			PreviousActivitySkipCommentID int, 
			SkipComment nVarChar(300),
			EventEndTime datetime
		)  

	SET @CurrentTime = getdate()
	--------------------------------------------------------------------------------------------------------------
	-- Debugging variables - requires Local_SA_DEBUG table in DB
	-------------------------------------------------------------------------------------------------------------
	DECLARE @DebugFlag int,
			@DebugSP [varchar](300),
			@DebugInputs [varchar](300),
			@DebugText [varchar](2000),
			@DebugTimestamp datetime,
			@NumActivities int

  --Enable Debug here by setting = 1 - Dont leave this set. Local_SA_Debug gets too big
	SELECT @DebugFlag = 0
	SELECT @DebugTimestamp = GETDATE() 
	SELECT @DebugSP = 'spLocal_SA_SkipPreviousActivity'
	SELECT @DebugInputs =@Eventsjson

	If @DebugFlag = 1 
		BEGIN 
			Select @DebugText = 'Starting :) '
			Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
		END

	---------------------------------------------------------------------------------------------------------------
	-- Check that the inputs passed to are json
	---------------------------------------------------------------------------------------------------------------
	IF (ISJSON(@Eventsjson) = 1)
			BEGIN
					Insert @Events(EventSubTypeId,PUId,EndTime)
					Select [EventSubTypeId],[PUId],[EndTime]
					FROM OPENJSON (@Eventsjson)  
							 WITH ([EventSubTypeId] varchar(200) '$.EventSubTypeId',
										[PUId] varchar(200) '$.PUId',
										[EndTime] varchar(200) '$.EndTime')
			END
	ELSE
		BEGIN
		If @DebugFlag = 1 
					BEGIN 
						Select @DebugText = '	WARNING. Input isnt json.'
						Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
					END
				SET NOCOUNT OFF  
				RETURN  
		END
	---------------------------------------------------------------------------------------------------------------
	-- Check that @events Contains sometning
	---------------------------------------------------------------------------------------------------------------
	IF (SELECT COUNT(*) FROM @Events) = 0  
    BEGIN
	If @DebugFlag = 1 
				BEGIN 
					Select @DebugText = 'Nothing to do. No events Passed'
					Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
				END
			SET NOCOUNT OFF  
			RETURN  
	END
	
	SET @RSUserId = (SELECT [User_Id] FROM dbo.Users WITH (NOLOCK) WHERE UserName = 'RTTSystem')
	SET @RSUserId = ISNULL(@RSUserId, 6)

	-- Check that the "Auto Skip Previous" option is set on the server. if it is not exit.
	SET @AutoSkipDisplayOptionId = (SELECT Display_Option_id FROM Display_Options WITH(NOLOCK) WHERE Display_Option_Desc = 'Auto Skip Previous')
	IF @AutoSkipDisplayOptionId is null
		BEGIN 
			If @DebugFlag = 1 
				BEGIN 
					Select @DebugText = 'Nothing to do. Auto Skip Previous Display Option not deployed on Server.'
					Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
				END
			SET NOCOUNT OFF  
			RETURN  
		END  
 
	-- Retrieve all sheets with that specified Event SubType and PUID
	INSERT @Activities (SheetID, EventEndTime)  
		SELECT s.Sheet_Id, e.EndTime from dbo.Sheets s WITH (NOLOCK) 
			JOIN @Events e ON s.Event_SubType_Id = e.EventSubTypeId  
			WHERE (s.Master_unit = e.PUId) and (s.Is_Active = 1)

	-- If there are no sheets(displays) configured for that event subtype and puid then exit 
	IF (SELECT COUNT(SheetID) FROM @Activities) = 0  
		BEGIN 
			If @DebugFlag = 1 
				BEGIN 
					Select @DebugText = 'Nothing to do. No Displays configured.'
					Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
				END
			SET NOCOUNT OFF  
			RETURN  
		END  
 
	If @DebugFlag = 1 
		BEGIN 
		SET @Exectime = DATEDIFF(ms,@DebugTimestamp,GETDATE())
			Set @NumActivities = (Select count(*) from @Activities);
			Select @DebugText = '  Starting @NumActivities= ' + convert(nvarchar(10),@NumActivities) + ': ' + convert(nVarChar(10),@Exectime) + ' msec'
			Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
		END
	-- determine if there are activites configured for this sheet and the autoskip option is set 
	UPDATE  @Activities
		SET  AutoSkipOption = Coalesce((SELECT value FROM Sheet_Display_Options WHERE Sheet_Id = sheetId And Display_Option_Id = @AutoSkipDisplayOptionId),0),
				HasActivities = Coalesce((SELECT value FROM Sheet_Display_Options WHERE Sheet_Id = sheetId And Display_Option_Id = 444),0)

	DELETE FROM @Activities
		WHERE (AutoSkipOption = 0 ) OR (HasActivities = 0)

	-- If there are no Activities that we should skip then exit 
	IF (SELECT COUNT(*) FROM @Activities) = 0  
		BEGIN  
			If @DebugFlag = 1 
				BEGIN 
					SET @Exectime = DATEDIFF(ms,@DebugTimestamp,GETDATE())
					Select @DebugText = 'Nothing to do. No Activities with Autoskip option set: '+ convert(nVarChar(10),@Exectime) + ' msec'
					Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
				END
			SET NOCOUNT OFF  
			RETURN  
		END  

	--get the previous Activity for that Sheet
	UPDATE  @Activities 
	SET PreviousActivityExecutionStartTime = (SELECT max(a.execution_start_time) FROM Activities a with(nolock) WHERE a.Sheet_ID = SheetID and execution_start_time < dateadd(ss, -60, EventEndTime))

	DELETE FROM @Activities
		WHERE PreviousActivityExecutionStartTime is Null


	UPDATE  @Activities 
	SET PreviousActivityID = a.Activity_id,
		PreviousActivityStatusID = a.Activity_Status,
		PreviousActivityLocked = Coalesce(a.Locked,0),
		PreviousActivitySkipCommentID = a.Skip_Comment_Id
	FROM Activities a with(nolock)
	WHERE a.execution_start_time = PreviousActivityExecutionStartTime
	and a.Sheet_ID = SheetID


		-- Dont skip not exististant actives (PreviousActivityID IS NULL) or if the activity statis is complete(3)  or skipped (4) or is locked.
	DELETE FROM @Activities
		WHERE (PreviousActivityID IS NULL) OR (PreviousActivityStatusID = 3) OR (PreviousActivityStatusID = 4) OR (PreviousActivityLocked = 1)


	-- If there are no Activities that we should skip then exit 
	IF (SELECT COUNT(*) FROM @Activities) = 0  
		BEGIN  
			If @DebugFlag = 1 
				BEGIN 
					SET @Exectime = DATEDIFF(ms,@DebugTimestamp,GETDATE())
					Select @DebugText = 'Nothing to do. No Activities that we need to autoskip: '+ convert(nVarChar(10),@Exectime) + ' msec'
					Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
				END
			SET NOCOUNT OFF  
			RETURN  
		END  
	If @DebugFlag = 1 
		BEGIN 
			SET @Exectime = DATEDIFF(ms,@DebugTimestamp,GETDATE())
			Set @NumActivities = (Select count(*) from @Activities);
			Select @DebugText = '  Updating @NumActivities= ' + convert(nvarchar(10),@NumActivities) + ': ' + convert(nVarChar(10),@Exectime) + ' msec'
			Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
		END

	UPDATE  @Activities 
	SET SkipComment = 'System Auto Skipped the activity '+CAST(PreviousActivityID AS nvarchar(20))+' when a new Activity was created.';
	

	-------------------------------------------------------------------------------------------
	-- This  cursor will go through each row in @Activities  table and  one by
	-- one skip the previous activity
	-------------------------------------------------------------------------------------------
	DECLARE
		@@PreviousActivityExecutionStartTime					datetime,   
		@@PreviousActivityID				int,
		@@PreviousActivitySkipCommentID int, 
		@@SkipComment nVarChar(300),
		@@SkipCommentId int,
		@@SheetID	int

	DECLARE	Activities_Cursor CURSOR FOR

	(SELECT PreviousActivityExecutionStartTime,	PreviousActivityID,  PreviousActivitySkipCommentID, SkipComment, SheetID  FROM	@Activities)

		FOR READ ONLY
	OPEN	Activities_Cursor
	FETCH	NEXT FROM Activities_Cursor INTO @@PreviousActivityExecutionStartTime, @@PreviousActivityID, @@PreviousActivitySkipCommentID, @@SkipComment, @@SheetID

	WHILE	@@Fetch_Status = 0

		BEGIN

			INSERT INTO Comments( Comment,
 	  	  	  	  				Comment_Text,
 	  	  	  	  				User_Id,
 	  	  	  	  				Entry_On,
 	  	  	  	  				CS_Id,
 	  	  	  	  				Modified_On )
 	  	  	  				VALUES(@@SkipComment, @@SkipComment, @RSUserId, @CurrentTime, 1, @CurrentTime)
 	  	  	  				SET @@SkipCommentId = Scope_Identity()
 	  	  	  				UPDATE Comments set TopOfChain_Id = Case when @@PreviousActivitySkipCommentID is not null then @@PreviousActivitySkipCommentID end where comment_Id = @@SkipCommentId 
 	  	  	  				SET @@SkipCommentId = Case when @@PreviousActivitySkipCommentID IS NULL THEN @@SkipCommentId ELSE @@PreviousActivitySkipCommentID END


			-- Directly update the Table, activity status = 4 (skipped) use current time
			UPDATE Activities
				-- Set the status of the activity to Skipped
				SET Activity_Status = 4,
 					End_Time =  @CurrentTime,
 					UserId = @RSUserId,
 					Skip_Comment_Id = @@SkipCommentId
 					--Complete_Type = @CompleteType
 				WHERE Activity_Id = @@PreviousActivityID
		

			--send this information to the Pending Results sets table
			INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
				SELECT 0, (SELECT ResultSetType = 4,
 	  	  	  				TopicId = 300,
 	  	  	  				MessageKey = PU_Id, -- Message Key
 	  	  	  				PUId =  PU_Id, -- Also put it in the topic result set
 	  	  	  				EventType= Activity_Type_Id ,
 	  	  	  				KeyId=KeyId1,
 	  	  	  				KeyTime=KeyId,
 	  	  	  				ActivityId= Activity_Id,
 	  	  	  				ActivityDesc = Activity_Desc ,
 	  	  	  				APriority = Activity_Priority ,
 	  	  	  				AStatus = 4,
 	  	  	  				StartTime = dbo.fnServer_CmnConvertFromDbTime(Start_Time ,'UTC'),
 	  	  	  				EndTime = dbo.fnServer_CmnConvertFromDbTime(@CurrentTime ,'UTC'),
 	  	  	  				TDuration = Target_Duration,
 	  	  	  				Title = Title,
 	  	  	  				UserId= @RSUserId,
 	  	  	  				EntryOn= dbo.fnServer_CmnConvertFromDbTime(EntryOn,'UTC'),
 	  	  	  				TransType=2,
 	  	  	  				PercentComplete = PercentComplete,
 	  	  	  				Tag = Tag ,
 	  	  	  				ExecutionStartTime = Execution_Start_Time,
 	  	  	  				AutoComplete = Auto_Complete,
 	  	  	  				ExtendedInfo = Extended_Info,
 	  	  	  				ExternalLink = External_Link,
 	  	  	  				TestsToComplete = Tests_To_Complete,
 	  	  	  				Locked = Locked,
 	  	  	  				CommentId = Comment_Id, 
 	  	  	  				OverdueCommentId = Overdue_Comment_Id,
 	  	  	  				SkipCommentId = @@SkipCommentId,
 	  	  	  				SheetId = Sheet_Id,
 	  	  	  				TransNum = 0,
 	  	  	  				LockActivity = Lock_Activity_Security,
 	  	  	  				NeedOverdueComment = Overdue_Comment_Security 
 	  	  	  				FOR XML PATH('row'), ROOT('rows') , TYPE),@RSUserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	  	  				FROM Activities 
 	  	  				WHERE Activity_Id = @@PreviousActivityID
			--- Delete the activity in the pending system completes table.				 
			DELETE Pending_SystemCompleteActivities
 				FROM Pending_SystemCompleteActivities P
				where P.Activity_id = @@PreviousActivityID
			If @DebugFlag = 1 
				BEGIN 
					Select @DebugText = '  Updating Activity: @@PreviousActivityID= ' + Isnull(convert(nvarchar(20),@@PreviousActivityID),'Null') +
					' /@@SheetID= ' + Isnull(convert(nvarchar(10), @@SheetID),'Null') +
					' /@@SkipCommentId= ' + Isnull(convert(nvarchar(10),@@SkipCommentId),'Null') +
					' /@@PreviousActivityExecutionStartTime= ' + Isnull(convert(nVarChar(25),@@PreviousActivityExecutionStartTime,120),'Null') 
   
						Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
					END
			FETCH	NEXT FROM Activities_Cursor INTO @@PreviousActivityExecutionStartTime, @@PreviousActivityID, @@PreviousActivitySkipCommentID, @@SkipComment, @@SheetID
		END
CLOSE 	Activities_Cursor
DEALLOCATE Activities_Cursor

If @DebugFlag = 1 
	BEGIN
		SET @Exectime = DATEDIFF(ms,@DebugTimestamp,GETDATE())
		Select @DebugText = 'Complete: ' + convert(nVarChar(10),@Exectime) + ' msec'
		Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
	END

SET NOCOUNT ,QUOTED_IDENTIFIER OFF
