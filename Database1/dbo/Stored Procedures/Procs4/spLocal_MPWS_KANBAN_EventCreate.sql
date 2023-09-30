
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_KANBAN_EventCreate
		
	This sp returns header info for spLocal_MPWS_KANBAN_EventCreate
	
	Date			Version		Build	Author  
	24-Feb-2020		1.0					Julien B. Ethier (Symasol)		FO-04099: Remove millisecond from DC event timestamp
  
*/	-------------------------------------------------------------------------------

CREATE  PROCEDURE [dbo].[spLocal_MPWS_KANBAN_EventCreate]
	@Message VARCHAR(50) OUTPUT,
	@KanbanID VARCHAR(25),
	@GCAS VARCHAR(25),
	@LocationCode VARCHAR(25),
	@MaterialName VARCHAR(50),
	@CriticalContainerCnt INT,
	@MaxContainerCnt INT,
	@RefillContainerCnt INT,
	@WeightSetpoint INT,
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
	@EUUser_Id INT,
	@EUStartTime DATETIME,
	@EUTimestamp DATETIME,
	@EUEvent_Id INT,
	@Result	VARCHAR(100),
	@EUVarId INT,
	@TestId INT,
	@EntryOn DATETIME


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
						IF (@RecordCount > 0)
							BEGIN
								SET @Message = 'Kanban location is already active'
							END
						ELSE
							BEGIN
								SELECT @EUUser_Id = User_Id
									FROM Users_Base 
									WHERE UserName = 'KanbanXface'
								SELECT @EUStartTime = MAX(Timestamp) 
									FROM Events
									WHERE PU_Id = @PU_Id;
								IF (@EUStartTime IS NULL)
									BEGIN
										-- 1.0
										SET @EUStartTime = CONVERT(DATETIME, CONVERT(VARCHAR(25), GETDATE(), 120));
									END
								-- Insert an event
								-- 1.0
								SET @EUTimestamp = CONVERT(DATETIME, CONVERT(VARCHAR(25), GETDATE(), 120));
								SET @EUEvent_Num = @KanbanID+'-'+CONVERT(VARCHAR(14), @EUTimestamp, 112)+REPLACE(CONVERT(VARCHAR(5),@EUTimestamp, 108),':','')
								EXECUTE @Result = dbo.spServer_DBMgrUpdEvent 
 										@EUEvent_Id OUTPUT, --Event_Id
 										@EUEvent_Num,		--Event_Num
 										@PU_Id,				--PU_Id
 										@EUTimestamp,		--Timestamp
 										NULL,				--Applied Product
 										NULL,				--Source Event
 										9,					--Event Status
 										1,					--Transaction Type
 										0,					--TransNum
										@EUUser_Id,			--User_Id
										NULL,				--CommentId
										NULL,				--EventSubTypeId
										NULL,				--TestingStatus
										@EUStartTime,		--StartTime
										NULL,				--EntryOn
										0,					--ReturnResultSet
 	  	  								NULL, 	  	  	  	-- Conformance
 	  	  								NULL, 	  	  	  	-- TestPctComplete
 	  	  								NULL, 	  	  	  	-- SecondUserId
 									  	NULL, 	  	  	  	-- ApproverUserId
 	  	  								NULL, 	  	  	  	-- ApproverReasonId 	 
 	  	  								NULL, 	  	  	  	-- UserReasonId
 	  	  								NULL, 	  	  	  	-- UserSignOffId
 	  	  								NULL, 	  	  	  	-- ExtendedInfo
 	  	  								1 	  	  	  	  	--Send Posts out
								SET @Message = 'Kanban Event Created'
								--Now start setting each of the variables
								--Update Test record
								SELECT @EUVarId = Var_Id 
									FROM Variables_Base
									WHERE PU_ID = @PU_Id
									  AND Var_Desc = 'GCASNumber'
								IF (@EUVarID IS NOT NULL)
									BEGIN
									EXECUTE dbo.spServer_DBMgrUpdTest2
											@Var_Id = @EUVarId,
											@User_Id = @EUUser_Id,
											@Canceled = 0,
											@New_Result = @GCAS,
											@Result_On = @EUTimestamp,
											@TransNum = 2,					--NOT USED, must be 0 or 2
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
								IF (@EUVarID IS NOT NULL)
									BEGIN
									EXECUTE dbo.spServer_DBMgrUpdTest2
											@Var_Id = @EUVarId,
											@User_Id = @EUUser_Id,
											@Canceled = 0,
											@New_Result = @LocationCode,
											@Result_On = @EUTimestamp,
											@TransNum = 2,					--NOT USED, must be 0 or 2
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
								IF (@EUVarID IS NOT NULL)
									BEGIN
									EXECUTE dbo.spServer_DBMgrUpdTest2
											@Var_Id = @EUVarId,
											@User_Id = @EUUser_Id,
											@Canceled = 0,
											@New_Result = @MaterialName,
											@Result_On = @EUTimestamp,
											@TransNum = 2,					--NOT USED, must be 0 or 2
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
								IF (@EUVarID IS NOT NULL)
									BEGIN
									EXECUTE dbo.spServer_DBMgrUpdTest2
											@Var_Id = @EUVarId,
											@User_Id = @EUUser_Id,
											@Canceled = 0,
											@New_Result = @Quantity,
											@Result_On = @EUTimestamp,
											@TransNum = 2,					--NOT USED, must be 0 or 2
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
									  AND Var_Desc = 'CriticalContainerCnt'
								IF (@EUVarID IS NOT NULL)
									BEGIN
									EXECUTE dbo.spServer_DBMgrUpdTest2
											@Var_Id = @EUVarId,
											@User_Id = @EUUser_Id,
											@Canceled = 0,
											@New_Result = @CriticalContainerCnt,
											@Result_On = @EUTimestamp,
											@TransNum = 2,					--NOT USED, must be 0 or 2
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
								IF (@EUVarID IS NOT NULL)
									BEGIN
									EXECUTE dbo.spServer_DBMgrUpdTest2
											@Var_Id = @EUVarId,
											@User_Id = @EUUser_Id,
											@Canceled = 0,
											@New_Result = @MaxContainerCnt,
											@Result_On = @EUTimestamp,
											@TransNum = 2,					--NOT USED, must be 0 or 2
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
								IF (@EUVarID IS NOT NULL)
									BEGIN
									EXECUTE dbo.spServer_DBMgrUpdTest2
											@Var_Id = @EUVarId,
											@User_Id = @EUUser_Id,
											@Canceled = 0,
											@New_Result = @RefillContainerCnt,
											@Result_On = @EUTimestamp,
											@TransNum = 2,					--NOT USED, must be 0 or 2
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
								IF (@EUVarID IS NOT NULL)
									BEGIN
									EXECUTE dbo.spServer_DBMgrUpdTest2
											@Var_Id = @EUVarId,
											@User_Id = @EUUser_Id,
											@Canceled = 0,
											@New_Result = @WeightSetpoint,
											@Result_On = @EUTimestamp,
											@TransNum = 2,					--NOT USED, must be 0 or 2
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

							END
					END
			END
		
	END


END


