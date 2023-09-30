
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_PLAN_CreateWorkOrder
		
	This sp returns header info for spLocal_MPWS_PLAN_CreateWorkOrder
	
	Date			Version		Build	Author  
	02-10-18		001			001		Don Reinert (GrayMatter)		Initial development	
	24-Feb-2020		1.1					Julien B. Ethier (Symasol)		FO-04099: Remove millisecond from DC event timestamp
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_PLAN_CreateWorkOrder]
	@Message VARCHAR(50) OUTPUT,
	@MaterialName VARCHAR(50),
	@GCASNumber VARCHAR(25),
	@DispenseNum INT,
	@TargetQty FLOAT,
	@UpperLimit FLOAT,
	@LowerLimit FLOAT,	
	@UOM VARCHAR(25),
	@DispensedQty INT,
	@Status VARCHAR(25),
	@DispenseStation VARCHAR(25)

AS

DECLARE
	@PU_Id INT,
	@EUEvent_Id INT,
	@EUEvent_Num VARCHAR(25),
	@EUUser_Id INT,
	@EUStartTime DATETIME,
	@EUTimestamp DATETIME,
	@NextEventNum VARCHAR(25),
	@Result	VARCHAR(100),
	@EUVarId INT,
	@TestId INT,
	@EntryOn DATETIME,
	@DispenseNumText VARCHAR(25),
	@TargetQtyText VARCHAR(25),
	@UpperLimitText VARCHAR(25),
	@LowerLimitText VARCHAR(25),
	@ProdStatus_Id INT

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT @PU_Id = PU_Id
	FROM Prod_Units_Base
	WHERE PU_Desc = 'KB-WO'

DECLARE @NotificationTime AS DATETIME 
SET @NotificationTime = GetDate()
DECLARE @ErrorCode AS INT
DECLARE @ErrorMessage AS Varchar(500)

IF (@PU_Id IS NULL)
	BEGIN
		SET @Message = 'Prod Unit KB-WO not set up'
		EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Inventory', 'Work Order not created, KB-WO not set up in SOA', @NotificationTime, 'Error'
	END
ELSE
	BEGIN
		IF (@TargetQty < @LowerLimit OR @TargetQty > @UpperLimit OR @LowerLimit < 0)
			BEGIN
				SET @Message = 'Invalid Target or Limit'
				EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Inventory', 'Work Order not created, Target Weight not within Limits', @NotificationTime, 'Warning'
			END
		ELSE
			BEGIN
				SELECT @ProdStatus_Id = ProdStatus_Id
					FROM Production_Status
					WHERE ProdStatus_Desc = @Status
				IF (@ProdStatus_Id iS NuLL)
					BEGIN
						SET @Message = 'Invalid Status'
						EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Inventory', 'Work Order not created, Status Invalid', @NotificationTime, 'Error'
					END
				ELSE
					BEGIN
						SET @DispenseNumText = CONVERT(VARCHAR(25), @DispenseNum)
						SET @TargetQtyText = CONVERT(VARCHAR(25), @TargetQty)
						SET @UpperLimitText  = CONVERT(VARCHAR(25), @UpperLimit)
						SET @LowerLimitText  = CONVERT(VARCHAR(25), @LowerLimit)
						SELECT @EUUser_Id = User_Id
							FROM Users_Base 
							WHERE UserName = 'KanbanXface'
						SELECT @EUStartTime = MAX(Timestamp) 
							FROM Events
							WHERE PU_Id = @PU_Id;

						-- 1.1
						SET @EUStartTime = CONVERT(DATETIME, CONVERT(VARCHAR(25), GETDATE(), 120));
						SET @EUTimestamp = @EUStartTime
						SELECT @EUEvent_Num = MAX(Event_Num)
							FROM Events
							WHERE PU_Id = @PU_Id
						SET @NextEventNum = 'WO' + replicate('0',7-len(SUBSTRING(CONVERT(VARCHAR(10),CONVERT(INT,SUBSTRING(@EUEvent_Num, 3,9) + 1)),1,9))) + SUBSTRING(CONVERT(VARCHAR(10),CONVERT(INT,SUBSTRING(@EUEvent_Num, 3,9) + 1)),1,9)
						-- Insert an event
						EXECUTE @Result = dbo.spServer_DBMgrUpdEvent 
 								@EUEvent_Id OUTPUT, --Event_Id
 								@NextEventNum,		--Event_Num
 								@PU_Id,				--PU_Id
 								@EUTimestamp,		--Timestamp
 								NULL,				--Applied Product
 								NULL,				--Source Event
 								@ProdStatus_Id,		--Event Status
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
								AND Var_Desc = 'GCASNumber'
						IF (@EUVarID IS NOT NULL)
							BEGIN
							EXECUTE dbo.spServer_DBMgrUpdTest2
									@Var_Id = @EUVarId,
									@User_Id = @EUUser_Id,
									@Canceled = 0,
									@New_Result = @GCASNumber,
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
								AND Var_Desc = 'DispenseNum'
						IF (@EUVarID IS NOT NULL)
							BEGIN
							EXECUTE dbo.spServer_DBMgrUpdTest2
									@Var_Id = @EUVarId,
									@User_Id = @EUUser_Id,
									@Canceled = 0,
									@New_Result = @DispenseNumText,
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
								AND Var_Desc = 'TargetQty'
						IF (@EUVarID IS NOT NULL)
							BEGIN
							EXECUTE dbo.spServer_DBMgrUpdTest2
									@Var_Id = @EUVarId,
									@User_Id = @EUUser_Id,
									@Canceled = 0,
									@New_Result = @TargetQty,
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
								AND Var_Desc = 'UpperLimit'
						IF (@EUVarID IS NOT NULL)
							BEGIN
							EXECUTE dbo.spServer_DBMgrUpdTest2
									@Var_Id = @EUVarId,
									@User_Id = @EUUser_Id,
									@Canceled = 0,
									@New_Result = @UpperLimit,
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
								AND Var_Desc = 'LowerLimit'
						IF (@EUVarID IS NOT NULL)
							BEGIN
							EXECUTE dbo.spServer_DBMgrUpdTest2
									@Var_Id = @EUVarId,
									@User_Id = @EUUser_Id,
									@Canceled = 0,
									@New_Result = @LowerLimit,
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
								AND Var_Desc = 'UOM'
						IF (@EUVarID IS NOT NULL)
							BEGIN
							EXECUTE dbo.spServer_DBMgrUpdTest2
									@Var_Id = @EUVarId,
									@User_Id = @EUUser_Id,
									@Canceled = 0,
									@New_Result = @UOM,
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
								AND Var_Desc = 'DispensedQty'
						IF (@EUVarID IS NOT NULL)
							BEGIN
							EXECUTE dbo.spServer_DBMgrUpdTest2
									@Var_Id = @EUVarId,
									@User_Id = @EUUser_Id,
									@Canceled = 0,
									@New_Result = 0,
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
								AND Var_Desc = 'DispenseStation'
						IF (@EUVarID IS NOT NULL)
							BEGIN
							EXECUTE dbo.spServer_DBMgrUpdTest2
									@Var_Id = @EUVarId,
									@User_Id = @EUUser_Id,
									@Canceled = 0,
									@New_Result = '',
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
						SET @Message = 'Work Order ' + @NextEventNum + ' Created'
						EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Inventory', @Message, @NotificationTime, 'Message'
					END
			END
			SELECT @Message AS Message
	END
END
