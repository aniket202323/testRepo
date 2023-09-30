 
 
 
CREATE  	PROCEDURE [dbo].[spLocal_MPWS_DISP_CheckIfDispenseEventChangedPO]
		@ErrorCode				INT				OUTPUT,
		@ErrorMessage			VARCHAR(255)	OUTPUT,
		@FlgUpdateEvent			BIT				OUTPUT,
		@FromPPId				INT				OUTPUT,
		@ToPPId					INT				OUTPUT,
		@EventId				INT,
		@FromBOMFIId			INT,
		@ToBOMFIId				INT
--WITH ENCRYPTION	
AS	
 
-- test
--DECLARE
--		@ErrorCode				INT				,
--		@ErrorMessage			VARCHAR(255)	,
--		@FlgUpdateEvent			BIT				,
--		@FromPPId				INT				,
--		@ToPPId					INT				,
--		@EventId				INT = 124171,
--		@FromBOMFIId			INT = 0,
--		@ToBOMFIId				INT = 1895
-------------------------------------------------------------------------------
-- Check if dispensed Production event was assigned to a BOMformulation Item
-- that belongs to a different Process Order and update the BOMFormulationItem 
-- UDP for the event
/*
declare @e int, @m varchar(255), @f bit, @fPPId int, @tPPId int
exec spLocal_MPWS_DISP_CheckIfDispenseEventChangedPO @e output, @m output, @f output, 
	@fPPId output, @tPPId output, 124171,0,1895
select @e, @m, @f, @fPPId, @tPPId  
*/
-- Date         Version Build Author  
-- 25-Nov-2015  001     001   Alex Judkowicz (GEIP)  Initial development
-- 14-Sep-2017  001     002   Susan Lee (GE Digital) Removed BOMFormulationItem	UDP as it has been replaced with event variable
-- 19-Sep-2017  001     003   Susan Lee (GE Digital) Check if BOM item qty is exceeded if dispense container is reassigned
-- 21-Nov-2017  001     004   Susan Lee (GE Digital) Remove BOM item qty check, this is to be done in iFIX with override capability
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
SET NOCOUNT ON;
 
DECLARE	@EDTableId			INT,
		@TFIdBOMFIId		INT,
		@ToBOMFIQty			FLOAT,
		@ToBOMProdId		INT,
		@DispenseQty		FLOAT,
		@ToBOMFIDispQty		FLOAT,
		@UpperTolerance		FLOAT
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
SELECT	@ErrorCode				= 1,
		@ErrorMessage			= 'Success',
		@EDTableId				= 14,
		@FlgUpdateEvent			= 0,
		@FromPPId				= -1,
		@ToPPId					= -1
-------------------------------------------------------------------------------
-- 1. Validate input parameters and configuration
-------------------------------------------------------------------------------
-- Check BOMFormulationItemID UDP configuration (Bill_Of_Material_Formulation_Items UDP)
-- SML: removed BOMFormulationItemID UDP and replaced with event variable
-------------------------------------------------------------------------------
--SELECT	@TFIdBOMFIId	= Table_Field_Id
--		FROM	dbo.Table_Fields		WITH (NOLOCK)
--		WHERE	Table_Field_Desc	= 'BOMFormulationItemID'
--		AND		TableId				= @EDTableId
 
--IF		@TFIdBOMFIId IS NULL
--BEGIN
--		SELECT	@ErrorCode		= -1,
--				@ErrorMessage	= 'BOMFormulationItemID UDP not configured'
--		RETURN		
--END	
-------------------------------------------------------------------------------
-- Get the PO, Qty, and ProdId for the passed ToBOMFIId
-------------------------------------------------------------------------------	
SELECT	@ToPPId			=	PP.PP_Id,
		@ToBOMFIQty		=	BOMFI.Quantity,
		@ToBOMProdId	=	BOMFI.Prod_Id
		FROM	dbo.Production_Plan PP							WITH (NOLOCK)
		JOIN	dbo.Bill_Of_Material_Formulation_Item BOMFI		WITH (NOLOCK) 	
		ON		BOMFI.BOM_Formulation_Id		= PP.BOM_Formulation_Id
		AND		BOMFI.BOM_Formulation_Item_Id	= @ToBOMFIId
 
IF		@ToPPId	IS NULL
BEGIN
		SELECT	@ErrorCode		= -2,
				@ErrorMessage	= 'Invalid Process Order'
		RETURN		
END
------------------------------------------------------------------------------
-- Retrieve event attributes
------------------------------------------------------------------------------
 
 
SELECT	@FromPPId		= ISNULL(PP_Id,-1),
		@DispenseQty	= Final_Dimension_X
		FROM	dbo.Event_Details 	WITH (NOLOCK)
		WHERE	Event_Id = @EventId
 
IF @FromBOMFIId <> 0 AND @FromPPId	IS NULL
	
BEGIN
		SELECT	@ErrorCode		= -3,
				@ErrorMessage	= 'Invalid Production Event'
		RETURN		
END	
 
 
------------------------------------------------------------------------------
-- Get Dispenses for To BOMFI
------------------------------------------------------------------------------
SELECT @ToBOMFIDispQty		= SUM(ED.Final_Dimension_X)
		FROM	dbo.Event_Details	ED		WITH (NOLOCK)
		JOIN	dbo.Variables_Base	V		WITH (NOLOCK)
		ON		V.PU_Id		= ED.PU_Id		
		AND		V.Test_Name	= 'MPWS_DISP_BOMFIId'
		JOIN	dbo.Tests			T		WITH (NOLOCK)
		ON		T.Var_Id	= V.Var_Id
		AND		T.Event_Id	= ED.Event_Id
		AND		T.Result	= @ToBOMFIId
 
------------------------------------------------------------------------------
-- Get Upper Tolerance
------------------------------------------------------------------------------
SELECT 
	@UpperTolerance = 1.0 + (CONVERT(FLOAT, CONVERT(VARCHAR(255), Prop_MaterialDef.Value)) / 100.0)
FROM [dbo].[Products_Aspect_MaterialDefinition]  Prod_MaterialDef
	JOIN [dbo].[Property_MaterialDefinition_MaterialClass] Prop_MaterialDef ON Prod_MaterialDef.Prod_Id = @ToBOMProdId
		AND Prop_MaterialDef.Class = 'Pre-Weigh'
		AND Prop_MaterialDef.Name	=  'MPWSToleranceUpper'
		AND Prop_MaterialDef.MaterialDefinitionId = Prod_MaterialDef.Origin1MaterialDefinitionId
 
------------------------------------------------------------------------------
-- Validate BOMFI Quantity limit plus upper tolerance will not be exceeded
------------------------------------------------------------------------------
 
--IF (@ToBOMFIQty + @UpperTolerance < ISNULL(@ToBOMFIDispQty,0) + @DispenseQty)
--BEGIN
--		SELECT	@ErrorCode		= -4,
--				@ErrorMessage	= 'Reassign Incomplete: Disp. Amount exceeds BOM Qty plus Tolerance.'
--		RETURN	
--END
 
-------------------------------------------------------------------------------
-- Update the BOMFormulationItemID UDP linked to the event_id
-- SML: removed BOMFormulationItemID UDP and replaced with event variable
-------------------------------------------------------------------------------
--UPDATE	dbo.Table_Fields_Values
--		SET	Value				= @ToBOMFIId
--		WHERE	KeyId			= @EventId
--		AND		Table_Field_Id	= @TFIdBOMFIId
--		AND		TableId			= @EDTableId
-------------------------------------------------------------------------------
-- IF @ToBOMFI belongs to a different PO than the @FromBOMFI belongs to, then 
-- sends a flag to the caller workflow to update the  Event Details to point 
-- to the PO associated with the @ToBOMFI
-------------------------------------------------------------------------------		
IF	@FromPPId <> @ToPPId OR @FromBOMFIId = 0
		SELECT	@FlgUpdateEvent = 1

