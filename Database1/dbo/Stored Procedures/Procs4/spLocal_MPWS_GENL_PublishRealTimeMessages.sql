 
 
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_GENL_PublishRealTimeMessages]
	@Success			INT				OUTPUT,
	@ErrMsg				VARCHAR(300)	OUTPUT,
	@JumpToTime			DATETIME		OUTPUT,
 
	@ECId				INT,
	@Reserved1			VARCHAR(255),
	@Reserved2			VARCHAR(255),
	@Reserved3			VARCHAR(255),
 
	@TriggerNum			INT,
	@TriggerLastValue	VARCHAR(25),
	@TriggerNewValue	VARCHAR(25),
	@TriggerLastTime	DATETIME,
	@TriggerNewTime		DATETIME,
	-------------------------------------------------------------------------------
	-- Tag#1: time-based variable
	-------------------------------------------------------------------------------
	@Tag1LastValue		VARCHAR(25),
	@Tag1NewValue		VARCHAR(25),
	@Tag1LastTime		DATETIME,
	@Tag1NewTime		DATETIME,
	-------------------------------------------------------------------------------
	-- Tag#2: Available
	-------------------------------------------------------------------------------
	@Tag2LastValue		VARCHAR(25)	= NULL,
	@Tag2NewValue		VARCHAR(25)	= NULL,
	@Tag2LastTime		DATETIME	= NULL,
	@Tag2NewTime		DATETIME	= NULL,
	-------------------------------------------------------------------------------
	-- Tag#3: Available
	-------------------------------------------------------------------------------
	@Tag3LastValue		VARCHAR(25)	= NULL,
	@Tag3NewValue		VARCHAR(25)	= NULL,
	@Tag3LastTime		DATETIME	= NULL,
	@Tag3NewTime		DATETIME	= NULL,
	-------------------------------------------------------------------------------
	-- Tag#4: Available
	-------------------------------------------------------------------------------
	@Tag4LastValue		VARCHAR(25)	= NULL,
	@Tag4NewValue		VARCHAR(25)	= NULL,
	@Tag4LastTime		DATETIME	= NULL,
	@Tag4NewTime		DATETIME	= NULL,
	-------------------------------------------------------------------------------
	-- Tag#5: Available
	-------------------------------------------------------------------------------
	@Tag5LastValue		VARCHAR(25)	= NULL,
	@Tag5NewValue		VARCHAR(25)	= NULL,
	@Tag5LastTime		DATETIME	= NULL,
	@Tag5NewTime		DATETIME	= NULL
AS
-------------------------------------------------------------------------------
-- Publish real time messages using resultsets. The messages to be processed
-- reside in a local table populated by HMI displays that call SPROCs instead of
-- workflows to provide the best performance possible
/*
exec  spLocal_MPWS_PLAN_GetMaterialGCASList 14, '1,2,3,4,5,6,7,8,9'
*/
-- Date         Version Build Author  
-- 29-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
 
 
-------------------------------------------------------------------------------
-- Declare variables.
-------------------------------------------------------------------------------
DECLARE	@MaxProcessedDate	DATETIME,
		@MaxRows			INT,
		@RowCount			INT,
		@RowMax				INT,
		@Id					INT,
		@EventId			INT,
		@ResultsetId		INT,
		@TransactionType	INT,
		@Transnum			INT,
		@PurgeDays			INT
		
DECLARE	@tIds				TABLE 
(
		tId					INT				PRIMARY KEY		IDENTITY (1,1),
		Id					INT				NULL,
		EventId				INT				NULL,
		ResultsetId			INT				NULL,
		TransactionType		INT				NULL,
		Transnum			INT				NULL
)		
-------------------------------------------------------------------------------
-- Initialize variables.
-------------------------------------------------------------------------------
SELECT	@Success 		= 1,
		@ErrMsg 		= NULL
-------------------------------------------------------------------------------
-- Exit if this is a stuttering
-------------------------------------------------------------------------------
IF	@TriggerNewValue = @TriggerLastValue
	OR	(@TriggerNewValue	<> '0'
		AND	@TriggerNewValue <> '1')
BEGIN
	RETURN
END
-------------------------------------------------------------------------------
-- If the passed timestamp is before than the last parentRoll.StartTime then
-- load the JumpToTime with the last starttime and return
-------------------------------------------------------------------------------
SELECT	@MaxProcessedDate	= NULL
SELECT	@MaxProcessedDate	= MAX(ProcessedDate)
		FROM	dbo.Local_MPWS_GENL_RealTimeMessages	WITH	(NOLOCK)
 
IF	@MaxProcessedDate	IS NOT NULL
BEGIN
	IF	@TriggerNewTime	<= @MaxProcessedDate
	BEGIN
		SELECT	@JumpToTime	= @MaxProcessedDate
		RETURN
	END
END
-------------------------------------------------------------------------------
--Quit if nothing to process
-------------------------------------------------------------------------------
IF	NOT EXISTS (SELECT	Id
						FROM	dbo.Local_MPWS_GENL_RealTimeMessages	WITH	(NOLOCK)
						WHERE	ErrorCode = 0)
BEGIN
	RETURN
END
-------------------------------------------------------------------------------
-- Retrieve the model Parameters.
-------------------------------------------------------------------------------
EXEC	spCmn_ModelParameterLookup
		@MaxRows				OUTPUT,		
		@ECId,				
		'MaxRows',
		10		
		
EXEC	spCmn_ModelParameterLookup
		@PurgeDays				OUTPUT,		
		@ECId,				
		'PurgeDays',
		2		
-------------------------------------------------------------------------------
-- Delete old records
-------------------------------------------------------------------------------		
DELETE dbo.Local_MPWS_GENL_RealTimeMessages
		WHERE	ProcessedDate <= DATEADD(dd, @PurgeDays * -1, GETDATE())
-------------------------------------------------------------------------------
-- Get records to process
-------------------------------------------------------------------------------
INSERT	@tIds (Id, EventId, ResultsetId, TransactionType, Transnum)
		SELECT	TOP (@RowCount) Id, EventId, ResultSetId, TransactionType, 
				TransNum
				FROM	dbo.Local_MPWS_GENL_RealTimeMessages	WITH	(NOLOCK)
				WHERE	ErrorCode = 0
				ORDER
				BY		Id
				
SELECT	@RowMax	= @@ROWCOUNT				
-------------------------------------------------------------------------------
-- Loop through records to process
-------------------------------------------------------------------------------				
SELECT	@RowCount = 1
WHILE	@RowCount <= @RowMax
BEGIN
		SELECT	@Id					= Id,
				@EventId			= EventId, 
				@ResultsetId		= ResultsetId, 
				@TransactionType	= TransactionType, 
				@Transnum			= Transnum
				FROM	@tIds
				WHERE	tId			= @RowCount
		-------------------------------------------------------------------------------
		-- Publish resultset message for the record being looped
		-------------------------------------------------------------------------------				
		IF	@ResultsetId = 1
		BEGIN
				-------------------------------------------------------------------------------
				-- Production event (events table)
				-------------------------------------------------------------------------------				
				SELECT	1, NULL, @TransactionType, Event_Id, Event_Num, PU_Id, 
						TimeStamp, Applied_Product, NULL, Event_Status, NULL, 
						User_Id, 1, Conformance,Testing_Prct_Complete, Start_Time, 
						@Transnum, Testing_Status, Comment_Id, Event_Subtype_Id, 
						Entry_On, Approver_User_Id, Second_User_Id, Approver_Reason_Id, 
						User_Reason_Id, User_Signoff_Id, Extended_Info, Signature_id
						FROM	dbo.Events		WITH (NOLOCK)
						WHERE	Event_Id		= @EventId
		END
		ELSE
		IF	@ResultsetId = 2
		BEGIN
				-------------------------------------------------------------------------------
				-- Variables tests (tests table)
				-------------------------------------------------------------------------------				
				SELECT	2, T.Var_Id, V.PU_Id, T.Entry_By, T.Canceled, T.Result, 
						T.Result_On, @TransactionType, 1, T.Second_User_Id, 
						@Transnum, T.Event_Id, T.Array_Id, T.Comment_Id, T.Signature_Id
						FROM	dbo.Tests T		WITH (NOLOCK)
						JOIN	dbo.Variables_Base V	WITH (NOLOCK)
						ON		T.Test_Id			= @EventId
						AND		T.Var_Id			= V.Var_Id
		END		
		ELSE
		IF	@ResultsetId = 8
		BEGIN
				-------------------------------------------------------------------------------
				--User Defined Events (User_Defined_Events table)
				-------------------------------------------------------------------------------				
				SELECT	8, 0, UDE_Id, UDE_Desc, PU_Id, Event_Subtype_Id, Start_Time, 
						End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, Cause3, Cause4,
						Cause_Comment_Id, Action1, Action2, Action3, Action4, Action_Comment_Id,
						Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,
						Research_Comment_Id, Comment_Id, @TransactionType, UDE_Desc,@Transnum,
						User_Id, Signature_Id
						FROM	dbo.User_Defined_Events		WITH (NOLOCK)
						WHERE	UDE_Id		= @EventId
		END		
		ELSE
		IF	@ResultsetId = 10
		BEGIN
				-------------------------------------------------------------------------------
				-- Production event details (Event_Details table)
				-------------------------------------------------------------------------------				
				SELECT	10, 0, Entered_By, @TransactionType, @Transnum, Event_Id, 
						PU_Id, NULL, Alternate_Event_Num, Comment_Id, NULL, 
						NULL, NULL, NULL, NULL, Entered_On, PP_Setup_Detail_Id,
						Shipment_Item_Id, Order_Id, Order_Line_Id, PP_Id, 
						Initial_Dimension_X, Initial_Dimension_Y, Initial_Dimension_Z,
						Initial_Dimension_A, Final_Dimension_X, Final_Dimension_Y, 
						Final_Dimension_Z, Final_Dimension_A, Orientation_X, 
						Orientation_Y, Orientation_Z, Signature_Id
						FROM	dbo.Event_Details			WITH (NOLOCK)
						WHERE	Event_Id		= @EventId
		END	
		ELSE
		IF	@ResultsetId = 11
		BEGIN
				-------------------------------------------------------------------------------
				-- Genealogy (Event_components table)
				-------------------------------------------------------------------------------				
				SELECT	11, 0,user_id, @TransactionType, @Transnum, Component_Id, Event_Id,
						Source_Event_Id, Dimension_X, Dimension_Y, Dimension_Z, Dimension_A,
						Start_Coordinate_X, Start_Coordinate_Y, Start_Coordinate_Z, 
						Start_Coordinate_A, Start_Time, Timestamp, Parent_Component_Id,Entry_On,
						Extended_Info, PEI_Id, Report_As_Consumption, Signature_Id
						FROM	dbo.Event_Components			WITH (NOLOCK)
						WHERE	Component_Id		= @EventId
		END	
		ELSE
		IF	@ResultsetId = 15
		BEGIN
				-------------------------------------------------------------------------------
				-- Process Order (Production_Plan table)
				-------------------------------------------------------------------------------				
				SELECT	15, 0, @TransactionType, @Transnum, Path_Id, PP_Id, Comment_Id, Prod_Id,
						Implied_Sequence, PP_Status_Id, PP_Type_Id, Source_PP_Id, User_Id,
						Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date,
						Entry_On,Forecast_Quantity, Production_Rate, Adjusted_Quantity, Block_Number,
						Process_Order, NULL, NULL, NULL, NULL, BOM_Formulation_Id
						FROM	dbo.Production_Plan			WITH (NOLOCK)
						WHERE	PP_Id		= @EventId
		END			
		-------------------------------------------------------------------------------
		-- Mark row as processed
		-------------------------------------------------------------------------------				
		UPDATE	dbo.Local_MPWS_GENL_RealTimeMessages
				SET	ErrorCode		 = 1,
					ProcessedDate	= GETDATE(),
					ErrorMessage	= 'Success'
					WHERE	Id		= @Id	
		-------------------------------------------------------------------------------
		-- Move on to next row
		-------------------------------------------------------------------------------				
		SELECT	@RowCount = @RowCount + 1
END				
 
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_GENL_PublishRealTimeMessages] TO [public]
 
 
 
