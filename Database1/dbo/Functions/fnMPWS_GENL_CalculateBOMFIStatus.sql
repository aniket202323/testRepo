 
 
 
CREATE  FUNCTION [dbo].[fnMPWS_GENL_CalculateBOMFIStatus]
(
@BOMFIId		INT
)
RETURNS   INT
AS
-------------------------------------------------------------------------------
-- Figure out the BOMFI status
-- This function will have to be expanded to support all valid status transitions
/*
DECLARE	@BOMFINewStatusId INT
SELECT	@BOMFINewStatusId = 	dbo.fnMPWS_GENL_CalculateBOMFIStatus(5488260)
*/
-- Date         Version Build Author  
-- 25-Nov-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-- 18-Sep-2017  001     002   Susan Lee (GE Digital) Replace events_detail BOMFIId with tests
-------------------------------------------------------------------------------
BEGIN
		------------------------------------------------------------------------------
		-- Declare Variables
		------------------------------------------------------------------------------
		DECLARE	 @TFIdBOMFIId			INT,
				 @EDTableId				INT,
				 @PPId					INT,
				 @StatusIdDispensing	INT,
				 @StatusIdDispensed		INT,
				 @BOMFIStatusId			INT,
				 @BOMFIQuantity			FLOAT,
				 @DispensedQuantity		FLOAT,
				 @LowerTolerance		FLOAT,
				 @UpperTolerance		FLOAT,
				 @BOMFIProdId			INT;
 
		------------------------------------------------------------------------------
		-- Initialize variables
		------------------------------------------------------------------------------
		SELECT	@StatusIdDispensed = PP_Status_Id
				FROM	dbo.Production_Plan_Statuses		WITH (NOLOCK)
				WHERE	PP_Status_Desc = 'Dispensed'
 
		SELECT	@StatusIdDispensing = PP_Status_Id
				FROM	dbo.Production_Plan_Statuses		WITH (NOLOCK)
				WHERE	PP_Status_Desc = 'Dispensing'
				
		SELECT	 @EDTableId = 14		
 
		SELECT	@TFIdBOMFIId	= Table_Field_Id
		FROM	dbo.Table_Fields		WITH (NOLOCK)
		WHERE	Table_Field_Desc	= 'BOMFormulationItemID'
		AND		TableId				= @EDTableId
		-----------------------------------------------------------------------------
		-- Get PO and BOMFI attributes
		-----------------------------------------------------------------------------		
		SELECT	@BOMFIQuantity	= BOMFI.Quantity,
				@PPId			= PP.PP_Id,
				@BOMFIProdId	= BOMFI.Prod_Id
				FROM	dbo.Bill_Of_Material_Formulation_Item BOMFI		WITH (NOLOCK)
				JOIN	dbo.Production_Plan PP							WITH (NOLOCK)
				ON		BOMFI.BOM_Formulation_Id	 = PP.BOM_Formulation_Id
				AND		BOMFI.BOM_FOrmulation_Item_Id= @BOMFIId
 
		SELECT 
			@LowerTolerance = 1.0 - (CONVERT(FLOAT, CONVERT(VARCHAR(255), Prop_MaterialDef.Value)) / 100.0)
		FROM [dbo].[Products_Aspect_MaterialDefinition]  Prod_MaterialDef
			JOIN [dbo].[Property_MaterialDefinition_MaterialClass] Prop_MaterialDef ON Prod_MaterialDef.Prod_Id = @BOMFIProdId
				AND Prop_MaterialDef.Class = 'Pre-Weigh'
				AND Prop_MaterialDef.Name	=  'MPWSToleranceLower'
				AND Prop_MaterialDef.MaterialDefinitionId = Prod_MaterialDef.Origin1MaterialDefinitionId
 
		SELECT 
			@UpperTolerance = 1.0 + (CONVERT(FLOAT, CONVERT(VARCHAR(255), Prop_MaterialDef.Value)) / 100.0)
		FROM [dbo].[Products_Aspect_MaterialDefinition]  Prod_MaterialDef
			JOIN [dbo].[Property_MaterialDefinition_MaterialClass] Prop_MaterialDef ON Prod_MaterialDef.Prod_Id = @BOMFIProdId
				AND Prop_MaterialDef.Class = 'Pre-Weigh'
				AND Prop_MaterialDef.Name	=  'MPWSToleranceUpper'
				AND Prop_MaterialDef.MaterialDefinitionId = Prod_MaterialDef.Origin1MaterialDefinitionId
		------------------------------------------------------------------------------				
		-- Find amount dispensed for this BOMFIId
		------------------------------------------------------------------------------
		--SELECT	@DispensedQuantity	= SUM(ED.Initial_Dimension_X)
		--		FROM	dbo.Event_Details ED		WITH (NOLOCK)
		--		JOIN	dbo.Table_Fields_Values TFV	WITH (NOLOCK)
		--		ON		ED.PP_Id = @PPId
		--		AND		TFV.KeyId	= ED.Event_Id
		--		AND		TFV.Table_Field_Id = @TFIdBOMFIId
		--		AND		TFV.TableId	= @EDTableId
		--		AND		TFV.Value	= @BOMFIId
		SELECT		@DispensedQuantity = SUM(ED.Initial_Dimension_X)
				FROM	dbo.Event_Details ED		WITH (NOLOCK)
				JOIN	dbo.Events		  E			WITH (NOLOCK)
					ON	ED.Event_Id = E.Event_Id
				JOIN	dbo.Variables	  v			WITH (NOLOCK)
					ON	v.PU_Id	= E.PU_Id AND v.Test_Name = 'MPWS_DISP_BOMFIId'
				JOIN	dbo.Tests		  t			WITH (NOLOCK)
					ON t.Var_Id = v.Var_Id AND t.Result_On = E.TimeStamp 
		WHERE t.Result = @BOMFIId
						
		SELECT	@DispensedQuantity = COALESCE(@DispensedQuantity, 0)		
		------------------------------------------------------------------------------
		-- Figure out the new status and update the BOMFI Status UDP
		------------------------------------------------------------------------------
		IF		@DispensedQuantity >= @LowerTolerance * @BOMFIQuantity
				SELECT	@BOMFIStatusId	= @StatusIdDispensed
		ELSE
				SELECT	@BOMFIStatusId	= @StatusIdDispensing				
		
		RETURN @BOMFIStatusId
END
 
 
