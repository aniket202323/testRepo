
CREATE PROCEDURE [dbo].[spLocal_MPWS_KANBAN_EventSubtract]
	@Message VARCHAR(50) OUTPUT,
	@KanbanID VARCHAR(25),
	@Quantity DECIMAL 

AS

DECLARE
	@PU_Id INT,
	@TableFieldId INT,
	@TableID INT,
	@Value VARCHAR(25),
	@IsKanban INT,
	@RecordCount INT,
	@EUEvent_Num varchar(25),
	@EUApplied_Product INT,
	@EUApprover_Reason_id INT,
	@EUApprover_User_Id INT,
 	@EUSource_Event INT,
	@EUComment_Id INT,
	@EUEvent_Subtype_Id INT,
	@EUConformance INT,
 	@EUTesting_Prct_Complete INT,
	@EUTesting_Status INT,
 	@EUSecond_User_Id INT,
	@EUUser_Reason_Id INT,
 	@EUUser_Signoff_Id INT,
 	@EUExtended_Info INT,
	@EUUser_Id INT,
	@EUStartTime DATETIME,
	@EUTimestamp DATETIME,
	@EUEvent_Id INT,
	@Result	VARCHAR(100),
	@EUVarId INT,
	@TestId BIGINT,
	@EntryOn DATETIME,
	@Comment_Id INT,
	@Array_Id INT,
	@EUCurrent_Quantity DECIMAL,
	@EUNew_Quantity DECIMAL

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT @PU_Id = PU_Id
	FROM Prod_Units_Base
	WHERE PU_Desc = @KanbanID

IF (@PU_Id IS NULL)
	BEGIN
		SET @Message = 'Invalid Kanban'
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
				SET @Message = 'PU Property of Kanban not set'
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
						SET @Message = 'Kanban is inactive'
					END
				ELSE
					BEGIN
						SELECT @RecordCount = COUNT(*)
						   FROM Events
						   WHERE PU_Id = @PU_Id
						     AND Event_Status = 9
						IF (@RecordCount = 0)
							BEGIN
								SET @Message = 'Kanban has no events with Inventory status'
							END
						ELSE
							BEGIN
								SELECT @EUUser_Id = User_Id
									FROM Users_Base 
									WHERE UserName = 'KanbanXface'
								SELECT @EUEvent_Id = MAX(Event_Id) 
									FROM Events
									WHERE PU_Id = @PU_Id
									  AND Event_Status = 9
								SELECT @EUTimestamp = Timestamp
									FROM Events
									WHERE Event_id = @EUEvent_Id
								SELECT @EUVarId = Var_Id 
									FROM Variables_Base
									WHERE PU_ID = @PU_Id
									  AND Var_Desc = 'Quantity'
								IF (@EUVarID IS NOT NULL)
									BEGIN
										SELECT @EUCurrent_Quantity = CONVERT(DECIMAL,Result),
												@TestId = Test_Id,
												@Comment_Id = Comment_Id,
												@Array_Id = Array_id
											FROM Tests
											WHERE Var_Id = @EUVarId
											  AND Event_Id = @EUEvent_Id
										SET @EUNew_Quantity = @EUCurrent_Quantity - @Quantity
										IF(@EUNew_Quantity < 0)
											BEGIN
												SET @Message = 'There is only '+CONVERT(VARCHAR(20),@EUCurrent_Quantity)+' available'
											END
										ELSE
											IF (@EUNew_Quantity = 0)
												BEGIN
													SELECT @EUApplied_Product = Applied_Product,
															@EUEvent_Num = Event_Num,
															@EUApplied_Product = Applied_Product,
															@EUApprover_Reason_id = Approver_Reason_id,
															@EUApprover_User_Id = Approver_User_Id,
 															@EUSource_Event = Source_Event,
															@EUComment_Id = Comment_Id,
															@EUEvent_Subtype_Id = Event_Subtype_Id,
															@EUConformance = Conformance,
															@EUTesting_Prct_Complete = Testing_Prct_Complete,
															@EUTesting_Status = Testing_Status,
 															@EUSecond_User_Id =Second_User_Id,
															@EUUser_Reason_Id = User_Reason_id,
 															@EUUser_Signoff_Id = User_Signoff_Id,
 															@EUExtended_Info = Extended_Info,
															@EUStartTime = Start_Time,
															@EUTimestamp = Timestamp
														FROM Events
														WHERE Event_id = @EUEvent_Id
												-- Update the event
													EXECUTE dbo.spServer_DBMgrUpdEvent 
 															@EUEvent_Id OUTPUT, --Event_Id
 															@EUEvent_Num,		--Event_Num
 															@PU_Id,				--PU_Id
															@EUTimestamp,		--Timestamp
 															@EUApplied_Product,	--Applied Product
 															@EUSource_Event,	--Source Event
															8,					--Event Status
 															2,					--Transaction Type
 															0,					--TransNum
															@EUUser_Id,			--User_Id
															@EUComment_Id,		--CommentId
															@EUEvent_Subtype_Id,--EventSubTypeId
															@EUTesting_Status,	--TestingStatus
															@EUStartTime,		--StartTime
															NULL,				--EntryOn
															0,					--ReturnResultSet
 	  	  													@EUConformance, 	-- Conformance
						  	  								@EUTesting_Prct_Complete, -- TestPctComplete
 	  	  													@EUSecond_User_Id, 	-- SecondUserId
 									  						@EUApprover_User_Id,-- ApproverUserId
					 	  	  								@EUApprover_Reason_id, 	-- ApproverReasonId 	 
 	  	  													@EUUser_Reason_Id, 	-- UserReasonId
 	  	  													@EUUser_Signoff_Id, -- UserSignOffId
					 	  	  								@EUExtended_Info, 	-- ExtendedInfo
 	  	  													1 	  	  	  	  	--Send Posts out
													SET @Message = 'Kanban fully consumed'
												END
											ELSE
												BEGIN
													SET @EntryOn = GETDATE()
													SET @Result = CONVERT(VARCHAR(25),@EUNew_Quantity)
													EXECUTE dbo.spServer_DBMgrUpdTest2
														@Var_Id = @EUVarId,
														@User_Id = @EUUser_Id,
														@Canceled = 0,
														@New_Result = @Result,
														@Result_On = @EUTimestamp,
														@TransNum = 2,					--NOT USED, must be 0 or 2
														@CommentId = @Comment_Id,
														@ArrayId = @Array_Id,
														@EventId = @EUEvent_Id OUTPUT,
														@PU_Id = @PU_Id OUTPUT,
														@Test_Id = @TestId OUTPUT,
														@Entry_On = @EntryOn OUTPUT,
														@SecondUserId = NULL,
														@HasHistory = NULL,
														@SignatureId = NULL
													SET @Message = 'Kanban Quantity reduced to '+CONVERT(VARCHAR(20),@EUNew_Quantity)
												END
									END
							END
					END
			END
		
	END


END




