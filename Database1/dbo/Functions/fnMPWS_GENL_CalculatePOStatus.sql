 
 
 
CREATE  FUNCTION [dbo].[fnMPWS_GENL_CalculatePOStatus]
(
@PPId		INT
)
RETURNS  INT
AS
-------------------------------------------------------------------------------
-- Recalculate Process Order status

--/*
-- select pp_id from production_plan where process_order = '000906364498' and source_pp_id is not null
--SELECT	dbo.fnMPWS_GENL_CalculatePOStatus(1636)
--*/
-- Date				Version Build Author  
-- 25-Nov-2015		001     001		Alex Judkowicz (GEIP)	Initial development	
--	17-Aug-2017		001		002		Jim Cameron				Added checking for bomfi's being Released as well as Dispensing. if only 1 bomfi was dispensing and finished (Dispensed) then the entire PO was set to Dispensed.
--	20-Sep-2018		001		003		Susan Lee (GE Digital)	Rewrite calculation of PO status
--	30-Jan-2020		1.4				Julien B. Ethier		Fixed issue caused by dispensed and kitted qty were wrongly grouped together
--	27-Mar-2020		1.5				Julien B. Ethier		Fixed JOIN between Tests and Events table
-------------------------------------------------------------------------------
BEGIN

	 --test
	--DECLARE @PPID INT 
	--select @PPId = pp_id from production_plan where process_order = '000906364498' and source_pp_id is not null
------------------------------------------------------------------------------
-- Declare Variables
------------------------------------------------------------------------------
	DECLARE 
		@CurrentPOStatusId		INT,
		@CurrentPOStatusDesc	VARCHAR(50),
		@NewPOStatusId			INT,
		@NewPOStatusDesc		VARCHAR(50)

	DECLARE	 @POBOM	TABLE
	(	BOMFIId					INT,	
		ProdId					INT,	
		TargetQty				DECIMAL(10,3),
		UpperTargetQty			DECIMAL(10,3),
		LowerTargetQty			DECIMAL(10,3),
		DispensedQty			DECIMAL(10,3),
		KittedQty				DECIMAL(10,3),
		CurrentBOMFIStatus		VARCHAR(50),
		NewBOMFIStatus			VARCHAR(50),
		StatusOrder				INT
	)

	DECLARE @DispenseTmp	TABLE
	(
		BOMFIId			INT,
		DispensedQty	DECIMAL(10,3),
		KittedQty		DECIMAL(10,3)
	)

	DECLARE @Dispense	TABLE
	(
		BOMFIId			INT,
		DispensedQty	DECIMAL(10,3),
		KittedQty		DECIMAL(10,3)
	)

	DECLARE @POStatusList		TABLE
	(
		StatusOrder		INT,
		POStatus		VARCHAR(50)
	)

------------------------------------------------------------------------------
-- Initialize PO status list
------------------------------------------------------------------------------
INSERT INTO @POStatusList
	(StatusOrder, POStatus)
	VALUES
	(1,'Released'),
	(2,'Dispensing'),
	(3,'Dispensed'),
	(4,'Kitting'),
	(5,'Kitted')

------------------------------------------------------------------------------
-- Get current status
------------------------------------------------------------------------------
	SELECT	@CurrentPOStatusId =  pp.PP_Status_Id,
			@CurrentPOStatusDesc = pps.PP_Status_Desc
	FROM	dbo.Production_Plan				pp	WITH (NOLOCK)
	JOIN	dbo.Production_Plan_Statuses	pps WITH (NOLOCK)
		ON	pp.PP_Status_Id = pps.PP_Status_Id
	WHERE	pp.PP_Id = @PPId

------------------------------------------------------------------------------
-- If current status shouldn't be updated, return the same status
------------------------------------------------------------------------------

	IF @CurrentPOStatusDesc IN ('Pending','Complete','Cancelled','Ready for Production','Staged')
	BEGIN
		SELECT	@NewPOStatusId = @CurrentPOStatusId,
				@NewPOStatusDesc = @CurrentPOStatusDesc
	END
	ELSE
------------------------------------------------------------------------------
-- Calculate PO status
------------------------------------------------------------------------------
	BEGIN

	-- GET BOM
		INSERT INTO @POBOM
		(		
			BOMFIId	,
			TargetQty,
			UpperTargetQty,
			LowerTargetQty,
			DispensedQty,
			KittedQty,
			ProdId	,
			CurrentBOMFIStatus
		)
		SELECT	bomfi.BOM_Formulation_Item_Id,
				CONVERT(DECIMAL(10,3),bomfi.Quantity),
				CONVERT(DECIMAL(10,3),bomfi.Quantity),
				CONVERT(DECIMAL(10,3),bomfi.Quantity),
				0,
				0,
				bomfi.Prod_Id,
				tfv1.Value
		FROM dbo.Production_Plan					pp		WITH (NOLOCK)
		JOIN dbo.Bill_Of_Material_Formulation_Item	bomfi	WITH (NOLOCK) 
			ON bomfi.BOM_Formulation_Id = pp.BOM_Formulation_Id
		JOIN dbo.Tables								t		WITH (NOLOCK)
			ON t.TableName = 'Bill_Of_Material_Formulation_Item' 
		JOIN dbo.Table_Fields						tf1		WITH (NOLOCK)
			ON tf1.Table_Field_Desc = 'BOMItemStatus' 
			AND tf1.TableId = t.TableId 
		JOIN dbo.Table_Fields_Values				tfv1	WITH (NOLOCK)
			ON tfv1.KeyId = bomfi.BOM_Formulation_Item_Id 
			AND tfv1.TableId = t.TableId 
			AND tfv1.Table_Field_Id = tf1.Table_Field_Id 
		WHERE pp.PP_Id = @PPId



	-- update upper and lower tolerance qty
		UPDATE b
		SET LowerTargetQty = b.TargetQty * (1.0 - (CONVERT(DECIMAL(10,3), CONVERT(VARCHAR(255), Prop_MaterialDef.Value)) / 100.0))
			FROM @POBOM b
			JOIN [dbo].[Products_Aspect_MaterialDefinition]  Prod_MaterialDef  
				ON Prod_MaterialDef.Prod_Id = b.ProdId
			JOIN [dbo].[Property_MaterialDefinition_MaterialClass] Prop_MaterialDef 
				ON   Prop_MaterialDef.MaterialDefinitionId = Prod_MaterialDef.Origin1MaterialDefinitionId
				AND Prop_MaterialDef.Class = 'Pre-Weigh'
				AND Prop_MaterialDef.Name	=  'MPWSToleranceLower'

			UPDATE b
			SET	UpperTargetQty = b.TargetQty * (1.0 + (CONVERT(DECIMAL(10,3), CONVERT(VARCHAR(255), Prop_MaterialDef.Value)) / 100.0))
			FROM @POBOM b
			JOIN [dbo].[Products_Aspect_MaterialDefinition]  Prod_MaterialDef  
				ON Prod_MaterialDef.Prod_Id = b.ProdId
			JOIN [dbo].[Property_MaterialDefinition_MaterialClass] Prop_MaterialDef 
				ON   Prop_MaterialDef.MaterialDefinitionId = Prod_MaterialDef.Origin1MaterialDefinitionId
				AND Prop_MaterialDef.Class = 'Pre-Weigh'
				AND Prop_MaterialDef.Name	=  'MPWSToleranceUpper'


	-- get dispensed qty against BOM
		INSERT INTO @DispenseTmp
			(BOMFIId,DispensedQty, KittedQty)
			SELECT
				t.Result BOMFormulationItemID,
				SUM(ed.Final_Dimension_X) ,
				CASE 
					WHEN ps.ProdStatus_Desc IN ('Kitted','Ready For Production','Staged') 
						THEN SUM(ed.Final_Dimension_X)
					ELSE 0
					END
			FROM dbo.Events e
			JOIN dbo.Event_Details		ed WITH (NOLOCK)
				ON e.Event_Id = ed.Event_Id
			JOIN dbo.Tests				t  WITH (NOLOCK)
				ON e.Event_Id = t.Event_Id
			JOIN dbo.Variables_Base		v  WITH (NOLOCK)
				ON t.Var_Id = v.Var_Id
				AND v.PU_Id = e.PU_Id
			JOIN dbo.Production_Status	ps  WITH (NOLOCK)
				ON ps.ProdStatus_Id = e.Event_Status
			JOIN @POBOM  b 
				ON b.BOMFIId = CAST(t.Result AS INT)
			WHERE		v.Test_Name = 'MPWS_DISP_BOMFIId'
			GROUP BY	t.Result,
						ps.ProdStatus_Desc
		
		-- 1.4
		INSERT INTO @Dispense (BOMFIId,DispensedQty, KittedQty)
		SELECT BOMFIId, SUM(DispensedQty), SUM(KittedQty)
		FROM @DispenseTmp
		GROUP BY BOMFIId

		-- update dispensed and kitted qty in POBOM
		UPDATE	b
		SET		DispensedQty = disp.DispensedQty,	
				KittedQty = disp.KittedQty
		FROM    @POBOM b
		JOIN	@Dispense disp
			ON	disp.BOMFIId =  b.BOMFIId

		-- update new BOM status
		UPDATE b
		SET NewBOMFIStatus = 
		CASE
			WHEN DispensedQty = 0 THEN 'Released'
			WHEN DispensedQty > 0 AND DispensedQty < LowerTargetQty THEN 'Dispensing'
			WHEN DispensedQty >= LowerTargetQty AND KittedQty = 0 THEN 'Dispensed'
		    WHEN DispensedQty >= LowerTargetQty AND DispensedQty <> KittedQty THEN 'Kitting'
			WHEN DispensedQty >= LowerTargetQty AND DispensedQty = KittedQty THEN 'Kitted'
			ELSE @CurrentPOStatusDesc END
		FROM @POBOM b

		-- update status order
		UPDATE b
		SET StatusOrder = s.StatusOrder
		FROM	@POBOM  b
		JOIN	@POStatusList  s
			ON	s.POStatus = b.NewBOMFIStatus

		
		-- get new PO status
		SELECT @NewPOStatusDesc = CASE 
				WHEN Max(StatusOrder) = 1 THEN 'Released'
				WHEN Max(StatusOrder) = 2 OR (Max(StatusOrder) = 3 AND MIN(StatusOrder) < 3) THEN 'Dispensing'
				WHEN Max(StatusOrder) = 3 AND MIN(StatusOrder) = 3 THEN 'Dispensed'
				WHEN Max(StatusOrder) = 4 OR(Max(StatusOrder) = 5 AND MIN(StatusOrder) < 5) THEN 'Kitting'
				WHEN Max(StatusOrder) = 5 AND MIN(StatusOrder) = 5 THEN 'Kitted'
				ELSE 'unknown'/*@CurrentPOStatusDesc*/ END
		FROM @POBOM

		-- Get new PO status Id
		SELECT @NewPOStatusId = PP_Status_Id
		FROM	dbo.Production_Plan_Statuses	WITH (NOLOCK)
		WHERE	PP_Status_Desc = @NewPOStatusDesc

		--select * from @Dispense
		--select * from @POBOM
		--select @NewPOStatusDesc,@NewPOStatusId
		--select * from @POstatusList
	END -- PO is not in RFP or Staged

	RETURN @NewPOStatusId	
END
 
 
