 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_PLAN_SetPOStatus]
		@Action			INT,				-- 1:Release, 2:Hold, 3:Cancel
		@PPIdMask		VARCHAR(8000),
		@UserS95Id		VARCHAR(255),
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT
AS	
-------------------------------------------------------------------------------
-- Update status for passed POs
/*
exec spLocal_MPWS_PLAN_SetPOStatus 1, '28,29', 'Admin'
*/
-- Date         Version Build Author  
-- 25-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
--DECLARE	@tFeedback			TABLE
--(
--	Id						INT					IDENTITY(1,1)	NOT NULL,
--	ErrorCode				INT									NULL,
--	ErrorMessage			VARCHAR(255)						NULL
--)
 
DECLARE	@tPPId				TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	PPId					INT									NULL,
	PPStatusId				INT									NULL,
	PathId					INT									NULL
)	
 
DECLARE	@CountPO			INT,
		@CountUpdate		INT			
		
DECLARE	@RowCount			INT,
		@RowMax				INT,
		@PPId				INT,
		@PPStatusId			INT,
		@PathId				INT,
		@NewPPStatusId		INT,
		@RC					INT,
		@EntryOn			DATETIME,
		@UserId				INT,
		@InvalidTransition	INT		
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
SELECT	@InvalidTransition = 0		
-------------------------------------------------------------------------------
--  Translate Action into a PO status
--	Action		--> PO. Status
--	1			--> Released
--  2			--> PreWeigh Hold
--  3			--> Canceled
-------------------------------------------------------------------------------
SELECT	@NewPPStatusId = NULL
SELECT	@NewPPStatusId = PPS.PP_Status_Id
		FROM	dbo.Production_Plan_Statuses PPS			WITH (NOLOCK)
		JOIN	dbo.Property_Equipment_EquipmentClass PEE	WITH (NOLOCK)
		ON		PPS.PP_Status_Desc	= PEE.Value
		AND		PEE.Name			= 'Planning.Process Order Release Actions.' 
									+ CONVERT(VARCHAR(02), @Action)
 
IF		@NewPPStatusId IS NULL
BEGIN
 
		SELECT	@ErrorCode = -1,
				@ErrorMessage = 'Action not properly configured: ' + CONVERT(VARCHAR(02), @Action)
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (-1, 'Action not properly configured: ' + CONVERT(VARCHAR(02), @Action))		
		GOTO	ReturnResults
END	
-------------------------------------------------------------------------------
--  Translate User
-------------------------------------------------------------------------------		
SELECT	@UserId = NULL
SELECT	@UserId = UAP.User_Id
		FROM	dbo.Users_Aspect_Person UAP		WITH (NOLOCK)	
		JOIN	dbo.Person	P					WITH (NOLOCK)
		ON		UAP.Origin1PersonId	= P.PersonId
		AND		P.S95Id				= @UserS95Id
		
IF		@UserId IS NULL
		SELECT	@UserId = 1
-------------------------------------------------------------------------------
--  Parse PP Id string and into a table variable and get its current status
-------------------------------------------------------------------------------
INSERT	@tPPId (PPId)
		SELECT	*
		FROM	dbo.fnLocal_CmnParseListLong(@PPIdMask,',')
		
SELECT	@RowMax = @@ROWCOUNT		
 
UPDATE	T
		SET		T.PPStatusId	= PP.PP_Status_Id,
				T.PathId		= PP.Path_Id
				FROM	@tPPId T
				JOIN	dbo.Production_Plan PP		WITH (NOLOCK)
				ON		PP.PP_Id = T.PPId
------------------------------------------------------------------------------
-- Loop through received Process Orders
-------------------------------------------------------------------------------
SELECT	@RowCount = 1
WHILE	@RowCount <= @RowMax
BEGIN
		SELECT	@PPId		= PPId,
				@PPStatusId = PPStatusId,
				@PathId		= PathId
				FROM	@tPPId
				WHERE	Id	= @RowCount
		-------------------------------------------------------------------------------				
		-- Check if status transition is configured for this path
		-------------------------------------------------------------------------------	
		IF	EXISTS (SELECT PPS_Id
							FROM	dbo.Production_Plan_Status	WITH (NOLOCK)
							WHERE	Path_Id = @PathId
							AND		From_PPStatus_Id = @PPStatusId
							AND		To_PPStatus_Id	= @NewPPStatusId)
		BEGIN							
				-------------------------------------------------------------------------------
				-- Call SPServer that updates the database
				-------------------------------------------------------------------------------
				SELECT	@EntryOn = GETDATE()
				
				EXECUTE	dbo.spServer_DBMgrUpdProdPlan 
						@PPId				OUTPUT,		-- @PPId 				
						2, 								-- @TransType
						97, 							-- @TransNum	
						@PathId,	 					-- @PathId
						NULL, 							-- @CommentId
						NULL, 							-- @ProdId
						NULL,							-- @ImpliedSequence
						@NewPPStatusId,					-- @PPStatusId
						NULL,							-- @PPTypeId	
						NULL,							-- @SourcePPId
						@UserId,						-- @UserId
						NULL,							-- @ParentPPId
						NULL,							-- @ControlType
						NULL,							-- @ForecastStartTime
						NULL,							-- @ForecastEndTime
						@EntryOn,						-- @EntryOn
						NULL,							-- @ForecastQuantity
						NULL,							-- @ProductionRate
						NULL,							-- @AdjustedQuantity
						NULL,							-- @BlockNumber
						NULL,							-- @ProcessOrder
						NULL,							-- @TransactionTime
						NULL,							-- @Misc1
						NULL,							-- @Misc2
						NULL,							-- @Misc3	
						NULL,							-- @Misc4
						NULL,							-- @BOMFormulationId
						NULL,							-- @UserGeneral1
						NULL,							-- @UserGeneral2
						NULL,							-- @UserGeneral3	
						NULL							-- @ExtendedInfo
 
				IF	@RC = -100
				BEGIN
				
		SELECT	@ErrorCode = -2,
				@ErrorMessage = 'Error updating PO Id: ' + CONVERT(VARCHAR(25), COALESCE(@PPId, -1))
						--INSERT	@tFeedback (ErrorCode, ErrorMessage)
						--	VALUES (-2, 'Error updating PO Id: ' + CONVERT(VARCHAR(25), COALESCE(@PPId, -1)))
						GOTO	ReturnResults		
				END	
				-------------------------------------------------------------------------------
				-- TODO: transaction table for real-time message
				-------------------------------------------------------------------------------		
		END
		ELSE
		BEGIN
				-------------------------------------------------------------------------------
				-- Status transition is not allowed
				-------------------------------------------------------------------------------
				SELECT	@InvalidTransition = @InvalidTransition + 1
		END
		SELECT	@RowCount = @RowCount + 1
END	
-------------------------------------------------------------------------------
-- Build feedback message
-------------------------------------------------------------------------------
IF	@InvalidTransition = 0
 
		SELECT	@ErrorCode = 1,
				@ErrorMessage = 'Success'
	--INSERT	@tFeedback (ErrorCode, ErrorMessage)
	--		VALUES (1, 'Success')
ELSE
	IF		@RowMax = @InvalidTransition
	
		SELECT	@ErrorCode = -3,
				@ErrorMessage = 'Status was not update for ANY Process Order'
			--INSERT	@tFeedback (ErrorCode, ErrorMessage)
			--		VALUES (-3, 'Status was not update for ANY Process Order')
	ELSE
	
		SELECT	@ErrorCode = 2,
				@ErrorMessage = 'Status was not updated for: ' 
					+ CONVERT(VARCHAR(05), COALESCE(@InvalidTransition, -1)) 
					+ ' process orders'
			--INSERT	@tFeedback (ErrorCode, ErrorMessage)
			--		VALUES (2, 'Status was not updated for: ' 
			--		+ CONVERT(VARCHAR(05), COALESCE(@InvalidTransition, -1)) 
			--		+ ' process orders')
 
ReturnResults:				
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_PLAN_SetPOStatus] TO [public]
 
