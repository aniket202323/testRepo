CREATE PROCEDURE dbo.spAlarms_UpdateAlarm
 	  	  @AlarmId 	 Int,
		  @Ack bit,
		  @Cause1 int,
		  @Cause2 int,
		  @Cause3 int,
		  @Cause4 int,
		  @Action1 int,
		  @Action2 int,
		  @Action3 int,
		  @Action4 int,
		  @UserId int,
		  @TransNum int
 	  	
AS

Declare
@CurrentAck bit,
@CurrentResearchOpenDate datetime,
@CurrentResearchCloseDate datetime,
@CurrentResearchUserId int,
@CurrentResearchStatusId int,
@CurrentSignature_Id int,
@CurrentCause1 int,
@CurrentCause2 int,
@CurrentCause3 int,
@CurrentCause4 int,
@CurrentAction1 int,
@CurrentAction2 int,
@CurrentAction3 int,
@CurrentAction4 int,
@CurrentEventReasonTreeDataId int,
@ActionTreeId INT,
@CauseTreeId INT,
@Found int =null,
@ReturnFromInnerSP int = null,
@ActionRequired bit ,
@CauseRequired bit,
@SourceVariableId INT


------------------------------------------------------------------------------
--  Getting the Current values from the Alarms table
------------------------------------------------------------------------------     

SELECT @Found = Alarm_Id, @CurrentAck = Ack, @CurrentSignature_Id = Signature_Id, @CurrentEventReasonTreeDataId = A.Event_Reason_Tree_Data_Id,
	   @CurrentAction1 = Action1, @CurrentAction2 = Action2, @CurrentAction3 = Action3, @CurrentAction4 = Action4,   
	   @CurrentCause1 = Cause1, @CurrentCause2 = Cause2, @CurrentCause3 = Cause3, @CurrentCause4 = Cause4, 
	   @CurrentResearchOpenDate = Research_Open_Date, @CurrentResearchCloseDate = Research_Close_Date,
	   @CurrentResearchUserId = Research_User_Id, @CurrentResearchStatusId = Research_Status_Id,
	   @ActionTreeId = AT.Action_Tree_Id, @CauseTreeId = AT.Cause_Tree_Id,
	   @ActionRequired = AT.Action_Required, @CauseRequired = AT.Cause_Required, @SourceVariableId = A.Key_Id
	FROM Alarms A JOIN Alarm_Template_Var_Data ATVD ON A.ATD_Id = ATVD.ATD_Id AND A.Alarm_Id = @AlarmId
	JOIN Alarm_Templates AT ON ATVD.AT_Id = AT.AT_Id;

IF ( @Found Is NULL)
	BEGIN
		SELECT Error = 'ERROR: AlarmId not valid', Code = 'InvalidData', ErrorType = 'ValidAlarmNotFound', PropertyName1 = 'AlarmId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @AlarmId , PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
 		RETURN
	END

------------------------------------------------------------------------------
--  Checking if the User is authorised for updation of this alarm 
------------------------------------------------------------------------------
DECLARE @AuthorizedSheets Table(Sheet_Id INT, Access_Level INT, Var_Id INT, PU_Id INT)
	;BEGIN TRY
			INSERT INTO @AuthorizedSheets EXEC spAlarms_GetAlarmSheets @UserId, @SourceVariableId, NULL
		END TRY
		BEGIN CATCH
			SELECT Error = 'User will not be able to update this Alarm, No authorized alarm sheets configured for this user', Code = 'InsufficientPermission', ErrorType = 'InsufficientPermission', PropertyName1 = 'UserName', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = (SELECT Username FROM Users_Base WHERE User_Id = @UserId), PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END CATCH;
	IF NOT EXISTS (SELECT 1 FROM @AuthorizedSheets)
		BEGIN
			SELECT Error = 'User is not authorized to the alarm sheet for updating this Alarm data', Code = 'InsufficientPermission', ErrorType = 'InsufficientPermission', PropertyName1 = 'UserName', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = (SELECT Username FROM Users_Base WHERE User_Id = @UserId), PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
 			RETURN
		END
---------------------------------------------------------------------------------			

IF @TransNum NOT IN(1, 2)
       OR @TransNum IS NULL
        BEGIN
            SELECT ERROR = 'Invalid - Transaction Type Required',  Code = 'InvalidData', ErrorType = 'InvalidTransactionNumber', PropertyName1 = 'TransNum', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @TransNum , PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END
------------------------------------------------------------------------------
--  For transaction type = 1 Acknowledge Only Call
------------------------------------------------------------------------------ 
IF (@TransNum = 1)
	BEGIN
	  --Only use the Ack from input rest take from existing values
	  SELECT @Action1 = @CurrentAction1, @Action2 = @CurrentAction2, @Action3 = @CurrentAction3, @Action4 = @CurrentAction4, 
			 @Cause1 = @CurrentCause1, @Cause2 = @CurrentCause2, @Cause3 = @CurrentCause3, @Cause4 = @CurrentCause4 

      -- While acknowledging the alarm required parameters should not be null in db
	  IF(@Ack =1 AND @CauseRequired = 1 AND @Cause1 IS NULL)
		BEGIN
			SELECT Code = 'InvalidData', Error = 'Invalid - Cause is required when acknowledging this alarm', ErrorType = 'UpdateCauseBeforAcknowledge', PropertyName1 = 'Cause1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Cause1, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END
	  IF(@Ack =1 AND @ActionRequired = 1 AND @Action1 IS NULL)
		BEGIN
			SELECT Code = 'InvalidData', Error = 'Invalid - Action is required when acknowledging this alarm', ErrorType = 'UpdateActionBeforAcknowledge', PropertyName1 = 'Action1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action1, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END
			 
	END
------------------------------------------------------------------------------
--  For transaction type = 2 updation of actions , causes and acknowledge
------------------------------------------------------------------------------

IF (@TransNum = 2)
	BEGIN
	  -- While updating the alarm with ack = 1, required parameters should not be null
	  IF(@Ack =1 AND @CauseRequired = 1 AND @Cause1 IS NULL)
		BEGIN
			SELECT Code = 'InvalidData', Error = 'Invalid - Cause is required if acknowledging this Alarm', ErrorType = 'InvalidReqestBodyParameter', PropertyName1 = 'Cause1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Cause1, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END
	  IF(@Ack =1 AND @ActionRequired = 1 AND @Action1 IS NULL)
		BEGIN
			SELECT Code = 'InvalidData', Error = 'Invalid - Action is required if acknowledging this Alarm', ErrorType = 'InvalidReqestBodyParameter', PropertyName1 = 'Action1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action1, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END
		
		IF (@Ack IS NULL)
			BEGIN
				SET @Ack = @CurrentAck
			END

	-- Validate the Cause1,2,3,4
		If  @Cause1 is not null
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data WHERE Level1_Id = @Cause1 And Tree_Name_Id = @CauseTreeId)
			BEGIN
				SELECT Code = 'InvalidData', Error = 'Invalid - Cause 1 Not Found On Location', ErrorType = 'InvalidReqestBodyParameter', PropertyName1 = 'Cause1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Cause1, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN			
			END
		END
		If  @Cause2 is not null
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
							WHERE Level1_Id = @Cause1 And  Level2_Id = @Cause2 And Tree_Name_Id = @CauseTreeId)
			BEGIN
				SELECT Code = 'InvalidData', Error = 'Invalid - Cause 2 Not Found On Location', ErrorType = 'InvalidReqestBodyParameter', PropertyName1 = 'Cause2', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Cause2, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN			
			END
		END
		If  @Cause3 is not null
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
							WHERE Level1_Id = @Cause1 And  Level2_Id = @Cause2 And  Level3_Id = @Cause3 And Tree_Name_Id = @CauseTreeId)
			BEGIN
				SELECT Code = 'InvalidData', Error = 'Invalid - Cause 3 Not Found On Location', ErrorType = 'InvalidReqestBodyParameter', PropertyName1 = 'Cause3', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Cause3, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN			
			END
		END
		If  @Cause4 is not null
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
							WHERE Level1_Id = @Cause1 And  Level2_Id = @Cause2 And  Level3_Id = @Cause3 And  Level4_Id = @Cause4 And Tree_Name_Id = @CauseTreeId)
			BEGIN
				SELECT Code = 'InvalidData', Error = 'Invalid - Cause 4 Not Found On Location', ErrorType = 'InvalidReqestBodyParameter', PropertyName1 = 'Cause4', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Cause4, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN			
			END
		END
		
		-- Validating Action1,2,3,4
		IF  @Action1 is not null
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data WHERE Level1_Id = @Action1 And Tree_Name_Id = @ActionTreeId)
			BEGIN
				SELECT Code = 'InvalidData', Error = 'Invalid - Action 1 Not Found On Location', ErrorType = 'InvalidReqestBodyParameter', PropertyName1 = 'Action1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action1, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN			
			END
		END
		IF  @Action2 is not null
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
							WHERE Level1_Id = @Action1 And  Level2_Id = @Action2 And Tree_Name_Id = @ActionTreeId)
			BEGIN
				SELECT Code = 'InvalidData', Error = 'Invalid - Action 2 Not Found On Location', ErrorType = 'InvalidReqestBodyParameter', PropertyName1 = 'Action2', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action2, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN			
			END
		END
		IF  @Action3 is not null
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
							WHERE Level1_Id = @Action1 And  Level2_Id = @Action2 And  Level3_Id = @Action3 And Tree_Name_Id = @ActionTreeId)
			BEGIN
				SELECT Code = 'InvalidData', Error = 'Invalid - Action 3 Not Found On Location', ErrorType = 'InvalidReqestBodyParameter', PropertyName1 = 'Action3', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action3, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN			
			END
		END
		IF  @Action4 is not null
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
							WHERE Level1_Id = @Action1 And  Level2_Id = @Action2 And  Level3_Id = @Action3 And  Level4_Id = @Action4 And Tree_Name_Id = @ActionTreeId)
			BEGIN
				SELECT Code = 'InvalidData', Error = 'Invalid - Action 4 Not Found On Location', ErrorType = 'InvalidReqestBodyParameter', PropertyName1 = 'Action4', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action4, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN			
			END
		END

	END

-- Table to insert the result set from the core sproc which we dont wat to give to our core service
DECLARE  @AdditionalResultSet TABLE ( [Alarm_Id] [int] NOT NULL, [Ack] [bit] NOT NULL, [Alarm_Desc] [nvarchar](1000) NOT NULL,	
[End_Time] [datetime] NULL,	[Ack_On] [datetime] NULL, [Research_Open_Date] [datetime] NULL,	[Research_Close_Date] [datetime] NULL,	
[Start_Time] [datetime] NOT NULL,	[Cause1] [int] NULL,[ATD_Id] [int] NULL,[Alarm_Type_Id] [int] NOT NULL,	[Cause4] [int] NULL,[Key_Id] [int] NULL,
[Ack_By] [int] NULL,[Action2] [int] NULL,[Cause2] [int] NULL,[Cause3] [int] NULL,[Action_Comment_Id] [int] NULL,[Cause_Comment_Id] [int] NULL,[Action1] [int] NULL,	
[Research_Comment_Id] [int] NULL,[Action3] [int] NULL,[Action4] [int] NULL,	[Duration] [int] NULL,[Research_User_Id] [int] NULL,[Research_Status_Id] [int] NULL,
[Source_PU_Id] [int] NULL,[User_Id] [int] NOT NULL,	[Cutoff] [tinyint] NULL,[Max_Result] [dbo].[Varchar_Value] NULL,[Min_Result] [dbo].[Varchar_Value] NULL,
[Start_Result] [dbo].[Varchar_Value] NULL,[End_Result] [dbo].[Varchar_Value] NULL,[Modified_On] [datetime] NULL,[ATSRD_Id] [int] NULL,
[SubType] [int] NULL,[priority] [int] NOT NULL,[ATVRD_Id] [int] NULL,[ESignature_Level] [int] NULL)

INSERT INTO @AdditionalResultSet
-- Call the core sproc for updation
EXEC @ReturnFromInnerSP = spServer_AMgrUpdateAlarm @AlarmId,
		NULL,--@KeyId int,
		NULL,--@ATDId int,
		NULL,--@StartTime datetime,
		NULL,--@EndTime datetime,
		NULL,--@StartValue nvarchar(100),
		NULL,--@EndValue nvarchar(100),
		NULL,--@MinValue nvarchar(100),
		NULL,--@MaxValue nvarchar(100),
		@Ack,--@Ack int,
		NULL,--@AckOn datetime,
		NULL,--@AckBy int,
		NULL,--@AlarmDesc nVarchar(1000),
		@CurrentResearchOpenDate,--@ResearchOpenDate datetime,
		@CurrentResearchCloseDate,--@ResearchCloseDate datetime,
		@Cause1,--@Cause1 int,
		@Cause2,--@Cause2 int,
		@Cause3,--@Cause3 int,
		@Cause4,--@Cause4 int,
		@Action1,--@Action1 int,
		@Action2,--@Action2 int,
		@Action3,--@Action3 int,
		@Action4,--@Action4 int,
		NULL,--@AlarmTypeId int,
		null,--@CauseCommentId int,
		null,--@ActionCommentId int,
		@UserId,--@UserId int,
		NULL,--@PUId int,
		NULL,--@ResearchCommentId int,
		NULL,--@Duration int,
		@CurrentResearchUserId,--@ResearchUserId int,
		@CurrentResearchStatusId,--@ResearchStatusId int,
		NULL,--@Cutoff int,
		NULL,--@ATSRD_Id int,
		99,--@TransNum int,
		NULL,--@SubType int,
		@CurrentEventReasonTreeDataId,--@Event_Reason_Tree_Data_Id  Int = Null,  -- Used For Categories
		NULL,--@ATVRD_Id int = NULL,
		@CurrentSignature_Id,--@Signature_Id int = NULL,
		NULL--@PathId int = NULL

IF(@ReturnFromInnerSP = 2) -- Alarm Modified
	BEGIN
		EXEC spAlarms_GetAlarms  null, NULL ,NULL , null, @AlarmId ,null, null, null, null, null, @UserId 
 	  	
		-------------------------
		--send message
		--------------------------        
		EXEC spServer_DBMgrUpdPendingResultSet NULL, 13, @AlarmId, 2, 1, 6, @UserId
		--(13 -Table id for alarms in spServer_DBMgrUpdPendingResultSet sproc
		-- 2 - transacrtion type for update, 6 - Result type for Alarms messages )
	END
ELSE IF (@ReturnFromInnerSP = 4) -- Alarm Record not modified
	BEGIN
		SELECT Code = 'NotModified', Error = 'Alarm Record not updated', ErrorType = 'NotModified', PropertyName1 = 'AlarmId', PropertyName2 = 'Reason for being not modified', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @AlarmId, PropertyValue2 = 'Supplied Values same as in Data Base', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

