
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_KANBAN_EventUpdate
		
	This sp returns header info for spLocal_MPWS_KANBAN_EventUpdate
	
	Date			Version		Build	Author  
	24-Feb-2020		1.0					Julien B. Ethier (Symasol)		FO-04099: Remove millisecond from DC event timestamp
  
*/	-------------------------------------------------------------------------------

CREATE  PROCEDURE [dbo].[spLocal_MPWS_KANBAN_EventUpdate]
	@Message VARCHAR(50) OUTPUT,
	@KanbanID VARCHAR(25),
	@GCAS VARCHAR(25),  --Don't change on inventory
	@LocationCode VARCHAR(25),  --Don't change on inventory
	@MaterialName VARCHAR(50),  --Don't change on inventory
	@CriticalContainerCnt INT,
	@MaxContainerCnt INT,
	@RefillContainerCnt INT,
	@WeightSetpoint FLOAT,  --Don't change on inventory
	@Quantity INT,   --Don't change on inventory
	@UOM VARCHAR(25)
AS

DECLARE
	@PU_Id INT,
	@TableFieldId INT,
	@TableID INT,
	@Value VARCHAR(25),
	@IsKanban INT,
	@RecordCount INT,
	@EUEvent_Num varchar(25),
	@EUUser_Id INT,
	@EUStartTime DATETIME,
	@EUTimestamp DATETIME,
	@EUEvent_Id INT,
	@Result	VARCHAR(100),
	@EUVarId INT,
	@TestId INT,
	@EntryOn DATETIME,
	@EUApplied_Product INT,
 	@EUSource_Event INT,
	@EUComment_Id INT,
	@EUEvent_SubType_Id INT,
	@EUTesting_Status INT,
 	@EUConformance INT,
 	@EUTest_Prct_Complete INT,
 	@EUSecond_User_Id INT,
 	@EUApprover_User_Id INT,
 	@EUApprover_Reason_Id INT,
 	@EUUser_Reason_Id INT,
 	@EUUser_Signoff_Id INT,
 	@EUExtended_Info VARCHAR(255),
	@QtyChar VARCHAR(25),
	@QtyFloat FLOAT



BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @NotificationTime AS DATETIME 
SET @NotificationTime = GetDate()
DECLARE @ErrorCode AS INT
DECLARE @ErrorMessage AS varchar(225)

IF (@WeightSetpoint < 0)
	BEGIN
		SET @Message = 'Error: Weight Setpoint is less than 0'
	END
ELSE
	BEGIN
		IF (@Quantity < 0)
			BEGIN
				SET @Message = 'Error: DispenseNum is less than 0'
			END
		ELSE
			BEGIN
				IF (@CriticalContainerCnt > @MaxContainerCnt OR @CriticalContainerCnt < 0 OR @RefillContainerCnt > @MaxContainerCnt OR @MaxContainerCnt < 0 OR @MaxContainerCnt < 0)
					BEGIN
						SET @Message = 'Error: Invalid Container Count'
					END
				ELSE
					BEGIN
						IF (@GCAS IS NULL OR @GCAS = '' OR @MaterialName IS NULL OR @MaterialName = '')
							BEGIN
								SET @Message = 'Error: GCAS or Material Name not Valid'
							END
						ELSE
							BEGIN
								SELECT @PU_Id = PU_Id
									FROM Prod_Units_Base
									WHERE PU_Desc = @KanbanID
								IF (@PU_Id IS NULL)
									BEGIN
										SET @Message = 'Error: Invalid Kanban'
									END
								ELSE
									BEGIN
										SELECT @TableFieldId = Table_Field_Id, @TableID = tf.TableId
											FROM Table_Fields tf, Tables t
											WHERE t.TableName = 'Prod_Units'
											  AND t.TableId = tf.TableId
											  AND tf.Table_Field_Desc = 'Kanban'
										SELECT @Value = Value
											FROM Table_Fields_Values
											WHERE Table_Field_Id = @TableFieldId
											  AND TableId = @TableId
											  AND KeyID = @PU_Id
										IF (@Value IS NULL)
											BEGIN
												SET @Message = 'Error: PU Property of Kanban not set'
											END
										ELSE
											BEGIN
												SELECT @IsKanban = Value 
													FROM Table_Fields_Values tfv,Table_Fields tf, Tables t
													WHERE tfv.KeyId = @PU_Id
													  AND tfv.TableId = t.TableId
													  AND t.TableName = 'Prod_Units'
													  AND tfv.Table_Field_Id = tf.Table_Field_Id
													  AND tf.Table_Field_Desc = 'Kanban'
												IF (@IsKanban < 1)
													BEGIN
														SET @Message = 'Error: Kanban is inactive'
													END
												ELSE
													BEGIN
														SELECT @RecordCount = COUNT(*)
														   FROM Events
														   WHERE PU_Id = @PU_Id
															 AND Event_Status = 9
														IF (@RecordCount = 0)
															BEGIN
																SET @Message = 'Kanban location is already active'
															END
														ELSE
															BEGIN
																SELECT @EUUser_Id = User_Id
																	FROM Users_Base 
																	WHERE UserName = 'KanbanXface'
																SELECT @EUEvent_Id = MAX(Event_Id) 
																	FROM Events
																	WHERE PU_Id = @PU_Id
																	  AND Event_Status = 9;
																SELECT @EUEvent_Num = Event_Num,
																		@EUTimestamp = Timestamp,
 																		@EUApplied_Product = Applied_Product,
 																		@EUSource_Event = Source_Event,
																		@EUComment_Id = Comment_Id,
																		@EUEvent_SubType_Id = Event_Subtype_Id,
																		@EUTesting_Status = Testing_Status,
																		@EUStartTime = Start_Time,
 	  	  																@EUConformance = Conformance,
 	  	  																@EUTest_Prct_Complete = Testing_Prct_Complete,
 	  	  																@EUSecond_User_Id = Second_User_Id,
 									  									@EUApprover_User_Id = Approver_User_Id,
 	  	  																@EUApprover_Reason_Id = Approver_Reason_Id,
 	  	  																@EUUser_Reason_Id = User_Reason_Id,
 	  	  																@EUUser_Signoff_Id = User_Signoff_Id,
 	  	  																@EUExtended_Info = Extended_Info
																	FROM Events
																	WHERE Event_Id = @EUEvent_Id
																-- Update the event
																SET @EUTimestamp = CONVERT(DATETIME, CONVERT(VARCHAR(25), GETDATE(), 120));
																SET @EUEvent_Num = @KanbanID+'-'+CONVERT(VARCHAR(14), @EUTimestamp, 112)+REPLACE(CONVERT(VARCHAR(5),@EUTimestamp, 108),':','')
																EXECUTE @Result = dbo.spServer_DBMgrUpdEvent 
 																		@EUEvent_Id OUTPUT, --Event_Id
 																		@EUEvent_Num,		--Event_Num
 																		@PU_Id,				--PU_Id
 																		@EUTimestamp,		--Timestamp
 																		@EUApplied_Product,	--Applied Product
 																		@EUSource_Event,	--Source Event
 																		9,					--Event Status
 																		2,					--Transaction Type
 																		0,					--TransNum
																		@EUUser_Id,			--User_Id
																		@EUComment_Id,		--CommentId
																		@EUEvent_SubType_Id,--EventSubTypeId
																		@EUTesting_Status,	--TestingStatus
																		@EUStartTime,		--StartTime
																		NULL,				--EntryOn
																		0,					--ReturnResultSet
 	  	  																@EUConformance, 	-- Conformance
 	  	  																@EUTest_Prct_Complete, 	-- TestPctComplete
 	  	  																@EUSecond_User_Id, 	-- SecondUserId
 									  									@EUApprover_User_Id,-- ApproverUserId
 	  	  																@EUApprover_Reason_Id, -- ApproverReasonId 	 
 	  	  																@EUUser_Reason_Id, 	-- UserReasonId
 	  	  																@EUUser_Signoff_Id, -- UserSignOffId
 	  	  																@EUExtended_Info, 	-- ExtendedInfo
 	  	  																1 	  	  	  	  	--Send Posts out
																SET @Message = 'Kanban Event Updated'
																--Now start setting each of the variables 
																SELECT @EUVarId = Var_Id 
																	FROM Variables_Base
																	WHERE PU_ID = @PU_Id
																	  AND Var_Desc = 'CriticalContainerCnt'
																IF (@EUVarID IS NOT NULL AND @CriticalContainerCnt IS NOT NULL)
																	BEGIN
																	EXECUTE dbo.spServer_DBMgrUpdTest2
																			@Var_Id = @EUVarId,
																			@User_Id = @EUUser_Id,
																			@Canceled = 0,
																			@New_Result = @CriticalContainerCnt,
																			@Result_On = @EUTimestamp,
																			@TransNum = 0,					--0 Update fields that are not null to the new values, 2 Update all fields of Events to the values in Result set. 
																			@CommentId = NULL,
																			@ArrayId = NULL,
																			@EventId = @EUEvent_Id OUTPUT,
																			@PU_Id = @PU_Id OUTPUT,
																			@Test_Id = @TestId OUTPUT,
																			@Entry_On = @EntryOn OUTPUT,
																			@SecondUserId = NULL,
																			@HasHistory = NULL,
																			@SignatureId = NULL
																	END
																SELECT @EUVarId = Var_Id 
																	FROM Variables_Base
																	WHERE PU_ID = @PU_Id
																	  AND Var_Desc = 'MaxContainerCnt'
																IF (@EUVarID IS NOT NULL AND @MaxContainerCnt IS NOT NULL)
																	BEGIN
																	EXECUTE dbo.spServer_DBMgrUpdTest2
																			@Var_Id = @EUVarId,
																			@User_Id = @EUUser_Id,
																			@Canceled = 0,
																			@New_Result = @MaxContainerCnt,
																			@Result_On = @EUTimestamp,
																			@TransNum = 0,					--0 Update fields that are not null to the new values, 2 Update all fields of Events to the values in Result set. 
																			@CommentId = NULL,
																			@ArrayId = NULL,
																			@EventId = @EUEvent_Id OUTPUT,
																			@PU_Id = @PU_Id OUTPUT,
																			@Test_Id = @TestId OUTPUT,
																			@Entry_On = @EntryOn OUTPUT,
																			@SecondUserId = NULL,
																			@HasHistory = NULL,
																			@SignatureId = NULL
																	END
																SELECT @EUVarId = Var_Id 
																	FROM Variables_Base
																	WHERE PU_ID = @PU_Id
																	  AND Var_Desc = 'RefillContainerCnt'
																IF (@EUVarID IS NOT NULL AND @RefillContainerCnt IS NOT NULL)
																	BEGIN
																	EXECUTE dbo.spServer_DBMgrUpdTest2
																			@Var_Id = @EUVarId,
																			@User_Id = @EUUser_Id,
																			@Canceled = 0,
																			@New_Result = @RefillContainerCnt,
																			@Result_On = @EUTimestamp,
																			@TransNum = 0,					--0 Update fields that are not null to the new values, 2 Update all fields of Events to the values in Result set. 
																			@CommentId = NULL,
																			@ArrayId = NULL,
																			@EventId = @EUEvent_Id OUTPUT,
																			@PU_Id = @PU_Id OUTPUT,
																			@Test_Id = @TestId OUTPUT,
																			@Entry_On = @EntryOn OUTPUT,
																			@SecondUserId = NULL,
																			@HasHistory = NULL,
																			@SignatureId = NULL
																	END
																-- look at Qty now to determine which ones to update
																SELECT @EUVarId = Var_Id 
																	FROM Variables_Base
																	WHERE PU_ID = @PU_Id
																	  AND Var_Desc = 'Quantity'
																SELECT @QtyChar = Result, @QtyFloat = CONVERT(FLOAT, Result)
																	FROM Tests
																	WHERE Var_Id = @EUVarId
																	  AND Event_Id = @EUEvent_Id
																IF (@QtyFloat IS NOT NULL AND @QtyFloat <> 0)
																	BEGIN
																		SET @Message = 'Warning: ' + @KanbanID + ' Partial Update Only - Kanban is not empty - ' + Convert(varchar(5), @QtyFloat)
																		EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Inventory', @Message, @NotificationTime, 'Message'
																	END
																ELSE
																--Update Test record
																	BEGIN
																	SELECT @EUVarId = Var_Id 
																		FROM Variables_Base
																		WHERE PU_ID = @PU_Id
																		  AND Var_Desc = 'GCASNumber'
																	IF (@EUVarID IS NOT NULL AND @GCAS IS NOT NULL)
																		BEGIN
																		EXECUTE dbo.spServer_DBMgrUpdTest2
																				@Var_Id = @EUVarId,
																				@User_Id = @EUUser_Id,
																				@Canceled = 0,
																				@New_Result = @GCAS,
																				@Result_On = @EUTimestamp,
																				@TransNum = 0,					--0 Update fields that are not null to the new values, 2 Update all fields of Events to the values in Result set. 
																				@CommentId = NULL,
																				@ArrayId = NULL,
																				@EventId = @EUEvent_Id OUTPUT,
																				@PU_Id = @PU_Id OUTPUT,
																				@Test_Id = @TestId OUTPUT,
																				@Entry_On = @EntryOn OUTPUT,
																				@SecondUserId = NULL,
																				@HasHistory = NULL,
																				@SignatureId = NULL
																		END
																	SELECT @EUVarId = Var_Id 
																		FROM Variables_Base
																		WHERE PU_ID = @PU_Id
																		  AND Var_Desc = 'LocationCode'
																	IF (@EUVarID IS NOT NULL AND @LocationCode IS NOT NULL)
																		BEGIN
																		EXECUTE dbo.spServer_DBMgrUpdTest2
																				@Var_Id = @EUVarId,
																				@User_Id = @EUUser_Id,
																				@Canceled = 0,
																				@New_Result = @LocationCode,
																				@Result_On = @EUTimestamp,
																				@TransNum = 0,					--0 Update fields that are not null to the new values, 2 Update all fields of Events to the values in Result set. 
																				@CommentId = NULL,
																				@ArrayId = NULL,
																				@EventId = @EUEvent_Id OUTPUT,
																				@PU_Id = @PU_Id OUTPUT,
																				@Test_Id = @TestId OUTPUT,
																				@Entry_On = @EntryOn OUTPUT,
																				@SecondUserId = NULL,
																				@HasHistory = NULL,
																				@SignatureId = NULL
																		END
																	SELECT @EUVarId = Var_Id 
																		FROM Variables_Base
																		WHERE PU_ID = @PU_Id
																		  AND Var_Desc = 'MaterialName'
																	IF (@EUVarID IS NOT NULL AND @MaterialName IS NOT NULL)
																		BEGIN
																		EXECUTE dbo.spServer_DBMgrUpdTest2
																				@Var_Id = @EUVarId,
																				@User_Id = @EUUser_Id,
																				@Canceled = 0,
																				@New_Result = @MaterialName,
																				@Result_On = @EUTimestamp,
																				@TransNum = 0,					--0 Update fields that are not null to the new values, 2 Update all fields of Events to the values in Result set. 
																				@CommentId = NULL,
																				@ArrayId = NULL,
																				@EventId = @EUEvent_Id OUTPUT,
																				@PU_Id = @PU_Id OUTPUT,
																				@Test_Id = @TestId OUTPUT,
																				@Entry_On = @EntryOn OUTPUT,
																				@SecondUserId = NULL,
																				@HasHistory = NULL,
																				@SignatureId = NULL
																		END
																	SELECT @EUVarId = Var_Id 
																		FROM Variables_Base
																		WHERE PU_ID = @PU_Id
																		  AND Var_Desc = 'Quantity'
																	IF (@EUVarID IS NOT NULL AND @Quantity IS NOT NULL)
																		BEGIN
																		EXECUTE dbo.spServer_DBMgrUpdTest2
																				@Var_Id = @EUVarId,
																				@User_Id = @EUUser_Id,
																				@Canceled = 0,
																				@New_Result = @Quantity,
																				@Result_On = @EUTimestamp,
																				@TransNum = 0,					--0 Update fields that are not null to the new values, 2 Update all fields of Events to the values in Result set. 
																				@CommentId = NULL,
																				@ArrayId = NULL,
																				@EventId = @EUEvent_Id OUTPUT,
																				@PU_Id = @PU_Id OUTPUT,
																				@Test_Id = @TestId OUTPUT,
																				@Entry_On = @EntryOn OUTPUT,
																				@SecondUserId = NULL,
																				@HasHistory = NULL,
																				@SignatureId = NULL
																		END

																	SELECT @EUVarId = Var_Id 
																		FROM Variables_Base
																		WHERE PU_ID = @PU_Id
																		  AND Var_Desc = 'WeightSetpoint'
																	IF (@EUVarID IS NOT NULL AND @WeightSetpoint IS NOT NULL)
																		BEGIN
																		EXECUTE dbo.spServer_DBMgrUpdTest2
																				@Var_Id = @EUVarId,
																				@User_Id = @EUUser_Id,
																				@Canceled = 0,
																				@New_Result = @WeightSetpoint,
																				@Result_On = @EUTimestamp,
																				@TransNum = 0,					--0 Update fields that are not null to the new values, 2 Update all fields of Events to the values in Result set. 
																				@CommentId = NULL,
																				@ArrayId = NULL,
																				@EventId = @EUEvent_Id OUTPUT,
																				@PU_Id = @PU_Id OUTPUT,
																				@Test_Id = @TestId OUTPUT,
																				@Entry_On = @EntryOn OUTPUT,
																				@SecondUserId = NULL,
																				@HasHistory = NULL,
																				@SignatureId = NULL
																		END
																	SELECT @EUVarId = Var_Id 
																		FROM Variables_Base
																		WHERE PU_ID = @PU_Id
																		  AND Var_Desc = 'UOM'
																	IF (@EUVarID IS NOT NULL AND @UOM IS NOT NULL)
																		BEGIN
																		EXECUTE dbo.spServer_DBMgrUpdTest2
																				@Var_Id = @EUVarId,
																				@User_Id = @EUUser_Id,
																				@Canceled = 0,
																				@New_Result = @UOM,
																				@Result_On = @EUTimestamp,
																				@TransNum = 0,					--0 Update fields that are not null to the new values, 2 Update all fields of Events to the values in Result set. 
																				@CommentId = NULL,
																				@ArrayId = NULL,
																				@EventId = @EUEvent_Id OUTPUT,
																				@PU_Id = @PU_Id OUTPUT,
																				@Test_Id = @TestId OUTPUT,
																				@Entry_On = @EntryOn OUTPUT,
																				@SecondUserId = NULL,
																				@HasHistory = NULL,
																				@SignatureId = NULL
																		END
																	Set @Message = @KanbanID + ' Configuration Updated'
																	EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Inventory', @Message, @NotificationTime, 'Message'
																	Select @Message as Message
																END 
															END--here
													END
											END
									END
							END
					END
				END
			END
		--Select @Message as Message
	END
