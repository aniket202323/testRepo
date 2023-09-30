 
 
 
CREATE  	PROCEDURE [dbo].[spLocal_MPWS_KIT_GetPOBOMItems]
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(500) 	OUTPUT,
		@PathId					INT,
		@PONumber			VARCHAR(50)
			 
AS	
-------------------------------------------------------------------------------
-- Get BOM items for passed in process orders
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_KIT_GetPOBOMItems @ErrorCode OUTPUT,@ErrorMessage OUTPUT,29, '20151123145424'
select @ErrorCode as ErrorCode, @ErrorMessage as ErrorMessage
*/
-- Date         Version Build Author  
-- 06-JUN-2016  001     001		Chris Donnelly (GE Digital)	Initial development	
-- 22-Dec-2016	001		002		Jim Cameron (GE Digital)	Updated for CanOverrideQty and OverrideQuantity
-- 19-Sep-2017  001     003		Susan Lee (GE Digital)		Removed BOMFormulationItemID UDP check 
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
DECLARE	@tBOMFIStatusId		TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	BOMFIStatusId			VARCHAR(255)						NULL
)
 
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	PPId					INT									NULL,
	ProcessOrder			VARCHAR(25)							NULL,
	PPStatusId				INT									NULL,
	PPStatusDesc			VARCHAR(255)						NULL,
	BOMFIId					INT									NULL,
	BOMFormulationOrder		INT									NULL,
	ProdId					INT									NULL,
	ProdCode				VARCHAR(255)						NULL,
	ProdDesc				VARCHAR(255)						NULL,
	Quantity				FLOAT								NULL,
	DispensedQuantity		FLOAT								NULL,
	RemainingQuantity		FLOAT								NULL,
	UOM						VARCHAR(255)						NULL,
	BOMFIStatusId			INT									NULL,
	BOMFIStatusDesc			VARCHAR(255)						NULL,
	EngUnitId				INT									NULL
)
	
DECLARE	@TableIdBOMFI					INT	,
		@TableIdEventDetail				INT ,
		@TableFieldIdBOMItemStatus		INT	,
		@TableFieldIdBOMFIId			INT ,
		@CntMin							INT ,
		@CntMax							INT 
		
-------------------------------------------------------------------------------
--  Validate Configuration
-------------------------------------------------------------------------------
SET	@ErrorCode = 1
SET	@ErrorMessage = 'Success'	
						
SELECT	@TableIdBOMFI			=	TableId
		FROM	dbo.[Tables]	WITH (NOLOCK)
		WHERE	TableName		=	'Bill_Of_Material_Formulation_Item'
IF		@TableIdBOMFI IS NULL
BEGIN
 
		SELECT	@ErrorCode = -1,
				@ErrorMessage = 'Cannot find Bill_Of_Material_Formulatio_Item table for UDP'
		GOTO ReturnData		
END
 
SELECT	@TableIdEventDetail		=	TableId
		FROM	dbo.[Tables]	WITH (NOLOCK)
		WHERE	TableName		=	'Event_Details'		
IF		@TableIdEventDetail IS NULL
BEGIN
 
		SELECT	@ErrorCode = -2,
				@ErrorMessage = 'Cannot find Event_Details table for UDP'
		GOTO ReturnData		
END		
 
-- Check to see if BOMItemStatus UDP is set up on Bill_Of_Material_Formulation_Item table
SELECT	@TableFieldIdBOMItemStatus = Table_Field_Id
		FROM	dbo.Table_Fields					WITH (NOLOCK)
		WHERE	TableId					= @TableIdBOMFI
		AND		Table_Field_Desc		='BOMItemStatus'
		
IF		@TableFieldIdBOMItemStatus IS NULL
BEGIN
		SELECT	@ErrorCode = -3,
				@ErrorMessage = 'BOM Item Status not configured'
		GOTO ReturnData		
END
 
-- Check to see if BOM_Formulation_Item_Id UDP is set up on Event_Details table
--SELECT	@TableFieldIdBOMFIId = Table_Field_Id
--		FROM	dbo.Table_Fields					WITH (NOLOCK)
--		WHERE	TableId					= @TableIdEventDetail
--		AND		Table_Field_Desc		='BOMFormulationItemId'
		
--IF		@TableFieldIdBOMFIId IS NULL
--BEGIN
--		SELECT	@ErrorCode = -4,
--				@ErrorMessage = 'BOM Formulation Item Id not configured'
--		GOTO ReturnData		
--END
-------------------------------------------------------------------------------
-- Use all status 
-------------------------------------------------------------------------------
INSERT	@tBOMFIStatusId	 (BOMFIStatusId)
		SELECT	PP_Status_Id 
				FROM	dbo.Production_Plan_Statuses	WITH (NOLOCK)		
 
------------------------------------------------------------------------------
--  Get process orders for the passed in execution path and PO Mask
-------------------------------------------------------------------------------
 
INSERT	@tOutput (PPId, ProcessOrder, BOMFIId, BOMFormulationOrder, ProdId, 
		ProdCode, ProdDesc, Quantity, DispensedQuantity, PPStatusId, PPStatusDesc, EngUnitId,
		BOMFIStatusId, BOMFIStatusDesc)
		SELECT	PP.PP_Id, PP.Process_Order, BOMFI.BOM_Formulation_Item_Id,
				BOMFI.BOM_Formulation_Order, BOMFI.Prod_Id, P.Prod_Code, P.Prod_Desc, 
				COALESCE(oq.Value, bomfi.Quantity), 0, PP.PP_Status_Id, PPS.PP_Status_Desc, BOMFI.Eng_Unit_Id,
				TFV.Value, PPS1.PP_Status_Desc
				FROM	dbo.Bill_Of_Material_Formulation_Item BOMFI		WITH (NOLOCK)
				JOIN	dbo.Production_Plan PP							WITH (NOLOCK)
					ON		PP.BOM_Formulation_Id		= BOMFI.BOM_Formulation_Id
					AND		PP.Path_Id					= @PathId
					AND		PP.Process_Order			= @PONumber
				JOIN	dbo.Products_Base P									WITH (NOLOCK)
					ON		BOMFI.Prod_Id				= P.Prod_Id
				JOIN	dbo.Production_Plan_Statuses PPS				WITH (NOLOCK)
					ON		PPS.PP_Status_Id			= PP.PP_Status_Id
				JOIN	dbo.Table_Fields_Values TFV		WITH (NOLOCK)
					ON		BOMFI.BOM_Formulation_Item_Id= TFV.KeyId
					AND		TFV.TableId					= @TableIdBOMFI
					AND		TFV.Table_Field_Id			= @TableFieldIdBOMItemStatus
				JOIN	dbo.Production_Plan_Statuses PPS1				WITH (NOLOCK)
					ON		PPS1.PP_Status_Id			= TFV.Value
				JOIN	@tBOMFIStatusId BOMS							
					ON		TFV.Value					= BOMS.BOMFIStatusId		
				OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'OverrideQuantity',  'Bill_Of_Material_Formulation_Item') oq
				ORDER
				BY		P.Prod_Code, PP.Process_Order
				
------------------------------------------------------------------------------
--  Get dispensed qty
-------------------------------------------------------------------------------
 
-- the dispense event bomfi id is no longer a UDP. it is in a variable Test_Name = 'MPWS_DISP_BOMFIId'
-- but this value is not used in the result so no need to query for it
 
--UPDATE	@tOutput
--SET		DispensedQuantity = 
--(SELECT SUM(ed.Initial_Dimension_X)
--		FROM	@tOutput	op
--		JOIN	dbo.Table_Fields_Values TFV		WITH (NOLOCK)
--			ON		TFV.Value = op.BOMFIId
--			AND		TFV.TableId = @TableIdEventDetail
--			AND		TFV.Table_Field_Id = @TableFieldIdBOMFIId
--		JOIN	Event_Details	ed				WITH (NOLOCK)
--			ON		ed.Event_Id	=	TFV.KeyId
--		GROUP BY op.BOMFIId)
		
-------------------------------------------------------------------------------
--  Get Remaining qty
-------------------------------------------------------------------------------
 
-- see Get dispensed qty above
 
--UPDATE	@tOutput
--SET		RemainingQuantity = Quantity - DispensedQuantity 
 
------------------------------------------------------------------------------
--  Get remaining PO attributes
------------------------------------------------------------------------------	
 
UPDATE	T
		SET	T.UOM						= EU.Eng_Unit_Code
			FROM	@tOutput T
			JOIN	dbo.Engineering_Unit EU			WITH (NOLOCK)				
			ON		T.EngUnitId			= EU.Eng_Unit_Id	
 
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
ReturnData:
 
SELECT	
		ProcessOrder					ProcessOrder,
		ProdId							MaterialId,
		ProdCode						Material,
		ProdDesc						MaterialDesccription,
		BOMFIStatusDesc					ItemStatus,
		ISNULL(Quantity,0)				Quantity
		FROM	@tOutput
		ORDER
		BY		Id
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_KIT_GetPOBOMItems] TO [public]
 
 
 
