
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DISP_CheckDate
		
	This sp returns header info for spLocal_MPWS_DISP_CheckDate
	
	Date			Version		Build	Author  
	03-7-18		001			001		Don Reinert (GrayMatter)		Initial development	

test
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_DISP_CheckUseByDate]
	@Message VARCHAR(50) OUTPUT,
	@UseByDate DATETIME OUTPUT,
	@DispenseId VARCHAR(50)

AS

DECLARE
	@PU_Id INT,
	@Prod_Id INT,
	@Value INT,
	@Event_Id INT,
	@Timestamp DATETIME,
	@TimeNow DATETIME,
	@ProdStatus_Id INT,
	@User_Id INT,
	@Result	VARCHAR(100),
	@EUStartTime DATETIME,
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
 	@EUExtended_Info VARCHAR(255) 

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT @TimeNow = GETDATE()

SELECT @PU_Id = PU_Id,
		@Event_Id = Event_Id,
		@Timestamp = Timestamp,
		@Prod_Id = Applied_Product
	FROM Events
	WHERE Event_Num = @DispenseId


SELECT @Value = MAX(CONVERT(INT, propDef.Value)) 
	FROM dbo.Products_Aspect_MaterialDefinition prodDef
	JOIN dbo.Property_MaterialDefinition_MaterialClass propDef ON propDef.MaterialDefinitionId = prodDef.Origin1MaterialDefinitionId
	WHERE propDef.Class = 'Pre-Weigh'
	  AND propDef.Name = 'UseByDate'
	  AND Prod_Id = @Prod_Id

SET	@UseByDate = DATEADD(DAY, CASE WHEN @Value IS NULL THEN 0 ELSE @Value END, @Timestamp)

IF (@UseByDate < @TimeNow)
	BEGIN
		SET @Message = 'Dispense Container expired - Putting on Hold'

		SELECT @ProdStatus_Id = ProdStatus_Id
			FROM Events, Production_Status
			WHERE Events.PU_Id = @PU_Id
			  AND Events.Event_Status = Production_Status.ProdStatus_Id
			  AND Production_Status.ProdStatus_Desc = 'Hold'
		SELECT @User_Id = User_Id
			FROM Users_Base 
			WHERE UserName = 'KanbanXface'
		SELECT	@EUSource_Event = Source_Event,
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
			WHERE Event_Id = @Event_Id
		-- Update the event
		EXECUTE @Result = dbo.spServer_DBMgrUpdEvent 
 				@Event_Id OUTPUT,   --Event_Id
 				@DispenseId,		--Event_Num
 				@PU_Id,				--PU_Id
 				@Timestamp,		    --Timestamp
 				@Prod_Id,	--Applied Product
 				@EUSource_Event,	--Source Event
 				@ProdStatus_Id,		--Event Status
 				2,					--Transaction Type
 				0,					--TransNum
				@User_Id,			--User_Id
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
	END
ELSE
	BEGIN
		SET @Message = 'Okay'
	END

IF (@Prod_Id IS NULL)
	SET	@Message = 'Invalid Material'
ELSE IF (@Value IS NULL)
	SET	@Message = 'UseByDate for Material not Set'

END

Select @Message AS Message
