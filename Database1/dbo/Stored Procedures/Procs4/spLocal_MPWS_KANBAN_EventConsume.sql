
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_KANBAN_EventConsume
		
	This sp returns header info for spLocal_MPWS_KANBAN_EventConsume
	
	Date			Version		Build	Author  
	24-Feb-2020		1.0					Julien B. Ethier (Symasol)		FO-04099: Remove millisecond from DC event timestamp
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_KANBAN_EventConsume]
	@Message VARCHAR(50) OUTPUT,
	@KanbanID VARCHAR(25)

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
	@Result VARCHAR(100)


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
 										8,					--Event Status
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
								SET @Message = 'Kanban Event Consumed'
							END
					END
			END
		
	END


END

