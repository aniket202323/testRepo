 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_PLAN_ResizePO]
		@PPId			INT,
		@NewQuantity	FLOAT,
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT
		
AS	
-------------------------------------------------------------------------------
-- Handle BOM Formulation items when a PO quantity is resized
/*
EXEC spLocal_MPWS_PLAN_SetPOPriority 9, '28,39,30,31,32,33,34,35,36'
 
 
*/
-- Date         Version Build Author  
-- 24-Oct-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
--DECLARE	@tFeedback			TABLE
--(
--	Id						INT					IDENTITY(1,1)	NOT NULL,
--	ErrorCode				INT									NULL,
--	ErrorMessage			VARCHAR(255)						NULL
--)
 
DECLARE	@tBOMFI				TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ProdId					INT									NULL,
	Quantity				FLOAT								NULL,
	Ratio					FLOAT								NULL,			
	NewQuantity				FLOAT								NULL,
	EngUnitId				INT									NULL,	
	LocationId				INT									NULL,
	LotDesc					VARCHAR(255)						NULL,
	LowerTolerance			FLOAT								NULL,
	LTolerancePrecision		INT									NULL,
	PUId					INT									NULL,
	QuantityPrecision		INT									NULL,
	ScrapFactor				FLOAT								NULL,
	UpperTolerance			FLOAT								NULL,
	UTolerancePrecision		INT									NULL,
	Alias					VARCHAR(255)						NULL
)
 
DECLARE	@tBOMFIFinal		TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ProdId					INT									NULL,
	Quantity				FLOAT								NULL,
	Ratio					FLOAT								NULL,			
	NewQuantity				FLOAT								NULL,
	EngUnitId				INT									NULL,	
	LocationId				INT									NULL,
	LotDesc					VARCHAR(255)						NULL,
	LowerTolerance			FLOAT								NULL,
	LTolerancePrecision		INT									NULL,
	PUId					INT									NULL,
	QuantityPrecision		INT									NULL,
	ScrapFactor				FLOAT								NULL,
	UpperTolerance			FLOAT								NULL,
	UTolerancePrecision		INT									NULL,
	Alias					VARCHAR(255)						NULL,
	BOMFormulationOrder		INT									NULL
)
 
DECLARE	@CurrentQuantity	FLOAT,
		@BOMFormulationId	INT,
		@MaxSequence		INT,
		@SearchPPId			INT	
-------------------------------------------------------------------------------
--  Retrieve PO attributes
------------------------------------------------------------------------------
SELECT	@SearchPPId		 = PP_Id,
		@CurrentQuantity = Forecast_Quantity,
		@BOMFormulationId= BOM_Formulation_Id
		FROM	dbo.Production_Plan			WITH (NOLOCK)
		WHERE	PP_Id = @PPId
		
IF		@SearchPPId IS NULL
BEGIN
        SELECT	@ErrorCode = -1,
				@ErrorMessage = 'Process Order Not Found'
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (-1, 'Process Order Not Found')		
		GOTO	ReturnResults
END	
 
IF		@BOMFormulationId IS NULL
BEGIN
		SELECT	@ErrorCode = -2,
				@ErrorMessage = 'Process Order without BOM Formulation'
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (-2, 'Process Order without BOM Formulation')		
		GOTO	ReturnResults
END		
-------------------------------------------------------------------------------
--  Get SUM for each BOM Item of this PO
------------------------------------------------------------------------------
INSERT	@tBOMFI (ProdId, Quantity, EngUnitId, LocationId,
		LotDesc, LowerTolerance, LTolerancePrecision, PUId, QuantityPrecision,
		ScrapFactor, UpperTolerance, UTolerancePrecision, Alias)
		SELECT	Prod_Id, SUM(Quantity), MAX(Eng_Unit_Id), MAX(Location_Id),
				MAX(Lot_Desc), MAX(Lower_Tolerance), MAX(LTolerance_Precision), 
				MAX(PU_Id), MAX(Quantity_Precision), MAX(Scrap_Factor), 
				MAX(Upper_Tolerance), MAX(UTolerance_Precision), MAX(Alias)
				FROM	dbo.Bill_Of_Material_Formulation_Item
				WHERE	BOM_Formulation_Id = @BOMFormulationId	
				GROUP
				BY		Prod_Id
-------------------------------------------------------------------------------
--  Get BOM Item amount to produce 1 FG and calculate the incremental quantity
-- for each BOM item for the new PO quantity
------------------------------------------------------------------------------				
UPDATE	@tBOMFI
		SET	Ratio = Quantity/@CurrentQuantity	
		
UPDATE	@tBOMFI
		SET	NewQuantity = (@NewQuantity * Ratio)- Quantity				
-------------------------------------------------------------------------------
--  Check if there are BOM items to be added 
-------------------------------------------------------------------------------
IF EXISTS (SELECT	Id
					FROM	@tBOMFI
					WHERE	NewQuantity > 0)
BEGIN							
		------------------------------------------------------------------------------
		--  Update priority for received POs
		-------------------------------------------------------------------------------
		SELECT	@MaxSequence	= MAX(BOM_Formulation_Order)
				FROM	dbo.Bill_Of_Material_Formulation_Item
				WHERE	BOM_Formulation_Id = @BOMFormulationId	
		------------------------------------------------------------------------------
		--  Move records to be added to a new table in order to get their new Sequences
		-------------------------------------------------------------------------------	
		INSERT	@tBOMFIFinal (ProdId, Quantity, EngUnitId, LocationId,
				LotDesc, LowerTolerance, LTolerancePrecision, PUId, QuantityPrecision,
				ScrapFactor, UpperTolerance, UTolerancePrecision, Alias, Ratio, NewQuantity)
				SELECT	ProdId, Quantity, EngUnitId, LocationId,
						LotDesc, LowerTolerance, LTolerancePrecision, PUId, QuantityPrecision,
						ScrapFactor, UpperTolerance, UTolerancePrecision, Alias, Ratio, 
						NewQuantity
						FROM	@tBOMFI
						WHERE	NewQuantity > 0
						ORDER
						BY		Id	
						
		UPDATE	@tBOMFIFinal
				SET	BOMFormulationOrder = @MaxSequence + Id		
		------------------------------------------------------------------------------
		--  Add new BOMFI records
		-------------------------------------------------------------------------------			
		INSERT	dbo.Bill_Of_Material_Formulation_Item (Prod_Id, Quantity, Eng_Unit_Id, 
				Location_Id, Lot_Desc, Lower_Tolerance, LTolerance_Precision, PU_Id,
				Quantity_Precision, Scrap_Factor, Upper_Tolerance, UTolerance_Precision,
				Alias, BOM_Formulation_Order, BOM_Formulation_Id)
				SELECT	ProdId, NewQuantity, EngUnitId, LocationId,
						LotDesc, LowerTolerance, LTolerancePrecision, PUId, QuantityPrecision,
						ScrapFactor, UpperTolerance, UTolerancePrecision, Alias,  
						BOMFormulationOrder, @BOMFormulationId
						FROM	@tBOMFIFinal
						ORDER
						BY		Id
						
		SELECT	@ErrorCode = 1,
				@ErrorMessage = 'Success'		
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (1, 'Success')					
		
END	
ELSE
		-------------------------------------------------------------------------------
		--  No records to be added
		-------------------------------------------------------------------------------
		SELECT	@ErrorCode = 2,
				@ErrorMessage = 'No BOM Formulation Items were added'
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (2, 'No BOM Formulation Items were added')		
		
ReturnResults:	
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_PLAN_ResizePO] TO [public]
 
 
 
 
