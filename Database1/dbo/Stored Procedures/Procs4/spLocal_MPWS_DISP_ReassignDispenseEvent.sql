 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_ReassignDispenseEvent]
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT,
		@EventId		INT,
		@FromBOMFIId	INT,
		@ToBOMFIId		INT,
		@UserName		VARCHAR(255)
AS	
-------------------------------------------------------------------------------
-- move a dispense event from a BOMFI to a different one
/*
declare @e int, @m varchar(255)
exec [dbo].[spLocal_MPWS_DISP_CreateDispenseEvent] @e output, @m output, 3372, 'ComxClient', 6511, 5, 1, 'kg', 5488260, 5738888, 'PW01D01-Scale01'
select @e, @m
*/
-- Date         Version Build Author  
-- 25-Nov-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
SET NOCOUNT ON;
 
DECLARE	@EDTableId			INT,
		@BOMFITableId		INT,
		@TransType			INT,
		@TransNum			INT,
		@UserId				INT,
		@TFIdBOMFIId		INT,
		@TFIdBOMFIStatus	INT,
		@PPId				INT,
		@RC					INT,
		@PUId				INT,
		@NewPPId			INT,
		@PPNewStatusId		INT,
		@PPStatusId			INT,
		@PPPathId			INT,
		@TimeStamp			DATETIME,
		@BOMFIStatus		INT,
		
		@BOMFITestId		INT,
		@BOMFIVarId			INT,
		@BOMFITestTimestamp	DATETIME
		
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
SELECT	@ErrorCode		= 1,
		@ErrorMessage	= 'Success',
		@TransType		= 2,
		@TransNum		= 0,
		@EDTableId		= 14,
		@BOMFITableId	= 28
		
SELECT	@TimeStamp		= CONVERT(DATETIME, CONVERT(VARCHAR(25), GETDATE(), 120))		
-------------------------------------------------------------------------------
-- 1. Validate input parameters and configuration
-------------------------------------------------------------------------------
-- Check the User
-------------------------------------------------------------------------------
SELECT	@UserId = User_Id
		FROM	dbo.Users_Base			WITH (NOLOCK)
		WHERE	Username	= @UserName
		
IF		@UserId	IS NULL
BEGIN
		SELECT	@ErrorCode		= -1,
				@ErrorMessage	= 'Invalid User'
		RETURN		
END	
-------------------------------------------------------------------------------
-- Check BOMItemStatus UDP configuration (Bill_Of_Material_Formulation_Items UDP)
-------------------------------------------------------------------------------
SELECT	@TFIdBOMFIId	= Table_Field_Id
		FROM	dbo.Table_Fields		WITH (NOLOCK)
		WHERE	Table_Field_Desc	= 'BOMFormulationItemID'
		AND		TableId				= @EDTableId
		
IF		@TFIdBOMFIId IS NULL
BEGIN
		SELECT	@ErrorCode		= -2,
				@ErrorMessage	= 'BOMFormulationItemID UDP not configured'
		RETURN		
END	
-------------------------------------------------------------------------------
-- Get the PO for the pasased BOMFIId
-------------------------------------------------------------------------------	
SELECT	@NewPPId		=	PP.PP_Id
		FROM	dbo.Production_Plan PP							WITH (NOLOCK)
		JOIN	dbo.Bill_Of_Material_Formulation_Item BOMFI		WITH (NOLOCK) 	
		ON		BOMFI.BOM_Formulation_Id		= PP.BOM_Formulation_Id
		AND		BOMFI.BOM_Formulation_Item_Id	= @ToBOMFIId
 
IF		@NewPPId	IS NULL
BEGIN
		SELECT	@ErrorCode		= -3,
				@ErrorMessage	= 'Invalid Process Order'
		RETURN		
END
-------------------------------------------------------------------------------
-- Check BOMItemStatus UDP configuration (Bill_Of_Material_Formulation_Items UDP)
-------------------------------------------------------------------------------
SELECT	@TFIdBOMFIStatus	= Table_Field_Id
		FROM	dbo.Table_Fields		WITH (NOLOCK)
		WHERE	Table_Field_Desc	= 'BOMItemStatus'
		AND		TableId				= @BOMFITableId
		
IF		@TFIdBOMFIStatus	IS NULL
BEGIN
		SELECT	@ErrorCode		= -4,
				@ErrorMessage	= 'BOMItemStatus UDP not configured'
		RETURN		
END	
------------------------------------------------------------------------------
-- Retrieve event attributes
------------------------------------------------------------------------------
SELECT	@PUId		= EV.PU_Id,
		@PPId		= ED.PP_Id,
		@PPStatusId	= PP.PP_Status_Id,
		@PPPathId	= PP.Path_Id
		FROM	dbo.Events EV				WITH (NOLOCK)
		JOIN	dbo.Event_Details ED		WITH (NOLOCK)
		ON		ED.Event_Id = EV.Event_Id
		AND		EV.Event_Id = @EventId
		JOIN	dbo.Production_Plan PP		WITH (NOLOCK)
		ON		ED.PP_Id	= PP.PP_Id
		
IF		@PUId	IS NULL
BEGIN
		SELECT	@ErrorCode		= -4,
				@ErrorMessage	= 'Invalid Production Event'
		RETURN		
END		
-------------------------------------------------------------------------------
-- Update the BOMFormulationItemID UDP linked to the event_id
-------------------------------------------------------------------------------
UPDATE	dbo.Table_Fields_Values
		SET	Value				= @ToBOMFIId
		WHERE	KeyId			= @EventId
		AND		Table_Field_Id	= @TFIdBOMFIId
		AND		TableId			= @EDTableId
		
------------------------------------------------------------------------------
-- Update the Dispense Event BOMFIId variable
------------------------------------------------------------------------------
SELECT
	@BOMFIVarId = v.Var_Id
FROM dbo.Variables_Base v WITH (NOLOCK)
WHERE v.PU_Id = @PUId
	AND v.Test_Name	= 'MPWS_DISP_BOMFIId'
 
SELECT 
	@BOMFITestTimestamp = Result_On 
FROM dbo.Tests t 
WHERE t.Var_Id = @BOMFIVarId 
	AND t.Event_Id = @EventId;
 
IF @BOMFIVarId IS NOT NULL AND @BOMFITestTimestamp IS NOT NULL
BEGIN
				
	EXEC @RC = dbo.SPServer_DBMgrUpdTest2
		@BOMFIVarId,			-- @var_Id			INT,
		@UserId,				-- @User_Id			INT,
		0,						-- @Canceled		INT
		@ToBOMFIId,				-- @New_Result		VARCHAR(25)
		@BOMFITestTimestamp,	-- @Result_On		DATETIME
		0,						-- @TransNum		INT
		NULL,					-- @CommentId		INT
		NULL,					-- @ArrayId			INT
		@EventId,				-- @EventId			INT
		@BOMFIVarId,			-- @PUId			INT
		@BOMFITestId OUTPUT,	-- @Test_Id			INT
		NULL,					-- @Entry_ON		DATETIME
		NULL					-- @SecondUserId	INT
		
END
 
 
-------------------------------------------------------------------------------
-- To BOMFII belongs to a different PO
-------------------------------------------------------------------------------		
IF	@PPId <> @NewPPId
BEGIN
		-------------------------------------------------------------------------------
		-- Update event details to point to the new PO 
		-------------------------------------------------------------------------------
		SELECT	@RC	= 0
		EXEC	@RC	=	dbo.SPServer_DBMgrUpdEventDet
				@UserId,
				@EventId,   
				@PUId,
				NULL,					-- Future1,
				2,						-- Transtype,
				@TransNum,				-- TransNum,
				NULL,					-- AltEventNum
				NULL,					-- Future2
				NULL,					-- InitialDimensionX
				NULL,					-- InitialDimensionY
				NULL,					-- InitialDimensionZ
				NULL,					-- InitialDimensionA
				NULL,					-- FinalDimensionX
				NULL,					-- FinalDimensionY
				NULL,					-- FinalDimensionZ
				NULL,					-- FinalDimensionA
				NULL,					-- OrientationX
				NULL,					-- OrientationY
				NULL,					-- OrientationZ
				NULL,					-- Future3
				NULL,					-- Future4
				NULL,					-- OrderId
				NULL,					-- OrderLineId
				@NewPPId,				-- PPId
				NULL,					-- PPSetupDetailId
				NULL,					-- ShipmentId
				NULL,					-- CommentId
				NULL,					-- EntryOn
				NULL,					-- Future5
				NULL,					-- Future6
				NULL					-- SignatureId
				
		IF		@RC < 0
		BEGIN
				SELECT	@ErrorCode		= @RC,
						@ErrorMessage	= 'Error updating production event details'
				RETURN		
		END	
		------------------------------------------------------------------------------
		--  Request real-time message publishing
		------------------------------------------------------------------------------
		INSERT	dbo.Local_MPWS_GENL_RealTimeMessages (EventId, ResultsetId, TransactionType, 
				TransNum, InsertedDate, ErrorCode)
				VALUES (@EventId, 10, 2, @TransNum, GETDATE(), 0)	
		-------------------------------------------------------------------------------
		-- Re-calculate the status for the old Process Order
		-------------------------------------------------------------------------------
		SELECT	@PPNewStatusId = dbo.fnMPWS_GENL_CalculatePOStatus(@PPId)					
		-------------------------------------------------------------------------------
		-- Call SPServer to update PO status
		-------------------------------------------------------------------------------
		IF	@PPStatusId <> @PPNewStatusId
		BEGIN
				EXECUTE	dbo.spServer_DBMgrUpdProdPlan 
						@PPId				OUTPUT, 				
						2, 			
						97, 				
						@PPPathId, 			
						NULL, 			
						NULL, 			
						NULL,
						@PPStatusId, 
						NULL,
						NULL, 
						@UserId,
						NULL,
						NULL, 
						NULL, 
						NULL, 
						@TimeStamp, 
						NULL, 
						NULL, 
						NULL,
						NULL, 
						NULL,
						NULL,
						NULL,
						NULL,
						NULL,
						NULL,
						NULL
				------------------------------------------------------------------------------
				--  Request real-time message publishing
				------------------------------------------------------------------------------
				INSERT	dbo.Local_MPWS_GENL_RealTimeMessages (EventId, ResultsetId, TransactionType, 
						TransNum, InsertedDate, ErrorCode)
						VALUES (@PPId, 15, 2, 97, GETDATE(), 0)
		END						
END
-------------------------------------------------------------------------------
-- Re-evaluate the Status of the FROm BOMFI
-------------------------------------------------------------------------------
SELECT	@BOMFIStatus = dbo.fnMPWS_GENL_CalculateBOMFIStatus(@FromBOMFIId)
 
UPDATE	dbo.Table_Fields_Values
		SET	Value					= @BOMFIStatus
		WHERE	KeyId				= @FromBOMFIId
		AND		Table_Field_Id		= @TFIdBOMFIStatus				
		AND		TableId				= @BOMFITableId			
-------------------------------------------------------------------------------
-- Re-evaluate the Status of the To BOMFI
-------------------------------------------------------------------------------
SELECT	@BOMFIStatus = dbo.fnMPWS_GENL_CalculateBOMFIStatus(@ToBOMFIId)	
 
UPDATE	dbo.Table_Fields_Values
		SET	Value					= @BOMFIStatus
		WHERE	KeyId				= @ToBOMFIId
		AND		Table_Field_Id		= @TFIdBOMFIStatus				
		AND		TableId				= @BOMFITableId		
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_ReassignDispenseEvent] TO [public]
 
 
 
 
 
