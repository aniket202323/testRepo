 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_GetPOsToDispense]
		@ErrorCode				INT				OUTPUT	,
		@ErrorMessage			VARCHAR(500)	OUTPUT	,
		@DispenseStationId		INT						, -- PU_ID of Dispense Unit
		@CheckMaterialFlag		BIT						, -- Yes=filter POs that contain materials that cannot be dispensed at this station.  No=return all POs. BOM Items 
		@Statuses				VARCHAR(255)			, -- Comma delimited list of statuses, PO Status "Released" or "Dispensing"
        --@MaterialId             INT              =NULL  , -- BOM ITEM Material to filter orders
        @PO_Num                 VARCHAR(255)     =NULL    -- Filter output by PO_Num
AS	
SET NOCOUNT ON
-------------------------------------------------------------------------------
 
-- @CheckMaterialFlag - join BOM_Formlation_Item.Prod_Id = PU_Products.PU_Id
 
-- Return list of POs in "Released" or "Dispensing" State
 
/*
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_DISP_GetPOsToDispense @ErrorCode output, @ErrorMessage output, 
4317, 0, 'Released,Dispensing', NULL, ''
 /* 6511  NULL */ /*@MaterialId*/, null /*null*/ /*'PO10' */ /*@PO_Num  */ --,Complete'
 
*/
 
-- Date         Version Build Author  
-- 06-Oct-2015  001     001    MK (GEIP)  Initial development
	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
DECLARE @iFixDecimals INT = 3;
 
DECLARE @paths TABLE
(
	Path_Id	INT
);
 
DECLARE 		
	@ClassName			VARCHAR(255),
	@PriorityLowToHigh	BIT
 
DECLARE		@POList			TABLE
(	
	Id					INT					IDENTITY(1,1)	NOT NULL,
	ProcessOrder		VARCHAR(255)	,	-- FROM PROD PLAN TABLE
	POPriority			INT				,	-- FROM Production_Plan , PROPERTY PreWeighProcessOrderPriority
	ProdId				INT				,  -- from prod plan table
	ProdCode			VARCHAR(50)		,  -- from products table Material   --validate number of characters
	ProdDesc			VARCHAR(50)		,  -- from products table Material Description --validate number of characters
	ForecastQty			FLOAT			,  -- from prod plan table
	DispensedQty		FLOAT			,  -- from production events, event_details we have UDP = BOMFormulationItemID , 
	UOM					VARCHAR(10)		, -- UOM of Process Order, validate datatype, select *, bom.Eng_Unit_Id from Bill_Of_Material_Formulation BOM
    POStatus			VARCHAR(50)     , -- validate number of characters, from prod plan table
    DispensePUDesc    VARCHAR(50),		  -- validate number of characters. WF equipmnent property DispensePO is actual value. Get comma dil string with all the dispense equipment where PApps PP.ID = WF property.DispensePO
	PP_Id				INT				, -- HELPER FIELD - FROM PROD PLAN TABLE
	BOM_Formulation_Id	BIGINT			 -- HELPER FIELD FROM PROD PLAN TABLE
)
 
DECLARE	@tStatuses				TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	Status					VARCHAR(255)						NULL
)
 
 
-------------------------------------------------------------------------------
--  Initialize values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	1,
		@ErrorMessage	=	'Success'
		
 
-------------------------------------------------------------------------------
-- Validate Parameters
-------------------------------------------------------------------------------
 
-------------------------------------------------------------------------------
-- <Actions>
 
-------------------------------------------------------------------------------
--  Parse @Statuses string and into a table variable 
-------------------------------------------------------------------------------
INSERT	@tStatuses (Status)
		SELECT	*
		FROM	dbo.fnLocal_CmnParseListLong(@Statuses,',')
 
-------------------------------------------------------------------------------
--  Populate data from production plan table. 
-------------------------------------------------------------------------------
INSERT @paths
	SELECT DISTINCT
		pep.Path_Id
	FROM dbo.Prdexec_Paths pep
		JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
		JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
	WHERE d.Dept_Desc = 'Pre-Weigh';
 
;WITH pos AS
(
	SELECT pp.PP_Id, PP.Process_Order, PP.Prod_Id, PP.Forecast_Quantity, PPS.PP_Status_Desc, PP.BOM_Formulation_Id, P.Prod_Code, P.Prod_Desc, EU.Eng_Unit_Code, MAX(pu.PU_Desc) PU_Desc
	FROM dbo.Production_Plan PP WITH (NOLOCK)
		INNER JOIN dbo.Production_Plan_Statuses PPS WITH (NOLOCK) ON PP.PP_Status_Id=PPS.PP_Status_Id
		INNER JOIN @tStatuses tSt ON tSt.Status = pps.PP_Status_Desc
		INNER JOIN dbo.Products_Base P WITH (NOLOCK) ON P.Prod_Id=PP.Prod_Id
		INNER JOIN dbo.Bill_Of_Material_Formulation BOM WITH (NOLOCK) ON BOM.BOM_Formulation_Id=PP.BOM_Formulation_Id
		INNER JOIN dbo.Engineering_Unit EU WITH (NOLOCK) ON eu.Eng_Unit_Id=BOM.Eng_Unit_Id
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON bomfi.BOM_Formulation_Id = BOM.BOM_Formulation_Id
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds
		LEFT JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = ds.Value
			AND pu.Equipment_Type = 'Dispense Station'
	WHERE pp.Path_Id IN (SELECT Path_Id FROM @paths)
	GROUP BY pp.PP_Id, PP.Process_Order, PP.Prod_Id, PP.Forecast_Quantity, PPS.PP_Status_Desc, PP.BOM_Formulation_Id, P.Prod_Code, P.Prod_Desc, EU.Eng_Unit_Code
)
INSERT INTO @POList (PP_Id, ProcessOrder, ProdId, ForecastQty, POStatus, BOM_Formulation_Id, ProdCode, ProdDesc, UOM, DispensePUDesc)	
	SELECT pos.PP_Id, pos.Process_Order, pos.Prod_Id, pos.Forecast_Quantity, pos.PP_Status_Desc, pos.BOM_Formulation_Id, pos.Prod_Code, pos.Prod_Desc, pos.Eng_Unit_Code, pos.PU_Desc -- dstat.PU_Desc
	FROM pos
	WHERE (pos.Process_Order LIKE '%' + @PO_Num + '%' OR ISNULL(@PO_Num, '') = '' OR pos.PU_Desc IS NOT NULL)	-- OR dstat.PU_Desc IS NOT NULL)
-- todo: filter by prdexec_paths
 
-------------------------------------------------------------------------------
--  GET PO priority
-------------------------------------------------------------------------------
UPDATE T
		SET T.POPriority = TFV.Value 
		FROM	dbo.Table_Fields_Values TFV		WITH (NOLOCK)
		JOIN	dbo.Tables TB					WITH (NOLOCK)
		ON		TFV.TableId			= TB.TableId
		AND		TB.TableName		= 'Production_Plan'
		JOIN	dbo.Table_Fields TF				WITH (NOLOCK)
		ON		TFV.Table_Field_Id	= TF.Table_Field_Id
		AND		TF.Table_Field_Desc	= 'PreWeighProcessOrderPriority'
		JOIN	@POList T 
		ON		T.PP_Id				= TFV.KeyId
 
-------------------------------------------------------------------------------
-- Filter by @MaterialId is sent in. we filter by BOM items. If any bom line contains material - show order
-------------------------------------------------------------------------------
--IF @MaterialId IS NOT NULL
--	DELETE FROM @POList 
--	WHERE NOT EXISTS
--	(
--	SELECT BOMI.Prod_Id 
--	FROM dbo.Bill_Of_Material_Formulation_Item BOMI WITH (NOLOCK) 
--	INNER JOIN @POList T ON T.BOM_Formulation_Id=BOMI.BOM_Formulation_Id
--	WHERE BOMI.Prod_Id=@MaterialId AND t.ProcessOrder=ProcessOrder
--	)
	
-------------------------------------------------------------------------------
-- Filter by @PO_Num is sent in
-------------------------------------------------------------------------------
--IF @PO_Num IS NOT NULL
--	DELETE FROM @POList WHERE LTRIM(RTRIM(ProcessOrder)) <> LTRIM(RTRIM(@PO_Num))
	
	
-------------------------------------------------------------------------------
-- Filter by @CheckMaterialFlag. If flag is yes, we output only those PO which bom items are assigned to PU_ID  @DispenseStationId
-------------------------------------------------------------------------------
IF @CheckMaterialFlag = 1
	BEGIN
	
		DELETE FROM @POList
		WHERE NOT EXISTS 
		(
		SELECT A.ProcessOrder
		FROM dbo.PU_Products PUP WITH (NOLOCK)
		INNER JOIN
		(SELECT BOMI.Prod_Id, t.ProcessOrder 
			FROM dbo.Bill_Of_Material_Formulation_Item BOMI WITH (NOLOCK) 
			INNER JOIN @POList T ON T.BOM_Formulation_Id=BOMI.BOM_Formulation_Id) A 
		ON A.Prod_Id = Pup.Prod_Id
		WHERE PUP.PU_Id=@DispenseStationId AND A.ProcessOrder=ProcessOrder
		GROUP BY A.ProcessOrder
		) 
 
	END
 
------------------------------------------------------------------------------
--  GET Dispense QTY. For now we do sum of event_details.initial_dim_X. we dont consider waste for now.
-- Alex suggested Correct: Dispensed Qty = SUM(InitialDimX) + SUM(Waste Amount)
------------------------------------------------------------------------------
 
--UPDATE @POList 
--	SET DispensedQty = A.QTY
--		FROM @POList T INNER JOIN
--		(
--		SELECT 	SUM(ED.Initial_Dimension_X) 'QTY', T.ProcessOrder --, TFV.Value, tfv.keyid 
--		FROM dbo.Table_Fields_Values TFV WITH (NOLOCK)
--		INNER JOIN	dbo.Tables TB WITH (NOLOCK) ON TFV.TableId	= TB.TableId AND TB.TableName = 'Event_Details'
--		INNER JOIN	dbo.Table_Fields TF	WITH (NOLOCK) ON TFV.Table_Field_Id	= TF.Table_Field_Id --AND TF.Table_Field_Desc	= 'BOMFormulationItemID'
--		INNER JOIN @POList T ON T.BOM_Formulation_Id = TFV.Value
--		INNER JOIN dbo.Event_Details ED ON ED.Event_ID = tfv.keyid
--		WHERE TF.Table_Field_Desc	= 'BOMFormulationItemID' --AND T.ProcessOrder = ProcessOrder
--		GROUP BY T.ProcessOrder
--		) A 
--		ON A.ProcessOrder = T.ProcessOrder
	
;WITH qty AS
(	
	SELECT
		po.ProcessOrder,
		SUM(ed.Final_Dimension_X) dQty
	FROM @POList po
		JOIN dbo.Event_Details ed ON ed.PP_Id = po.PP_Id
	GROUP BY po.ProcessOrder
)
UPDATE po
	SET DispensedQty = qty.dQty
	FROM @POList po
		JOIN qty ON qty.ProcessOrder = po.ProcessOrder
		      
------------------------------------------------------------------------------
--  GET DispensePUDesc. Returns all the dispense stations from WF, where Equipment property value 'DispensePO'= ProcessOrder from @POList
------------------------------------------------------------------------------                        
DECLARE @Names VARCHAR(8000) 
 
--UPDATE @POList 
--	SET DispensePUDesc = A.PU_Desc 
--	FROM @POList T INNER JOIN          
--		(SELECT	T.ProcessOrder,
--				CAST(( SELECT PU.PU_Desc + ''
--					FROM  dbo.Property_Equipment_EquipmentClass PEC WITH(NOLOCK) 
--					JOIN  dbo.PAEquipment_Aspect_SOAEquipment PAS         WITH(NOLOCK)
--					ON          PEC.EquipmentId   = PAS.Origin1EquipmentId
--					AND         PEC.Name = 'DispensePO'
--					AND         PEC.Class   ='Pre-Weigh - Dispense'
--					JOIN  dbo.Prod_Units_Base PU                                     WITH (NOLOCK)
--					ON          PAS.PU_Id   = PU.PU_Id
--					WHERE T.ProcessOrder = CONVERT(VARCHAR(255), PEC.Value)
--					FOR XML PATH ('')) AS VARCHAR(MAX)) as 'PU_Desc'
--		 FROM @POList T) A 
--			ON T.ProcessOrder = A.ProcessOrder
			
 
-------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
 
 
---- TODO: REMOVE THIS CHUNK. IT IS USED TO SIMULATE DIFFERENT PRIORITIES FOR iFIX TESTING
--;with a as
--(
--	select
--		*,
--		ROW_NUMBER() OVER(ORDER BY ProdId) rowno
--	from @POList
--)
--update a
--	set POPriority = rowno
 
SELECT 
	@PriorityLowToHigh = CAST(peec.Value AS BIT)
FROM dbo.Property_Equipment_EquipmentClass peec
	JOIN dbo.EquipmentClass_EquipmentObject eeo ON eeo.EquipmentId = peec.EquipmentId
WHERE peec.Name	= 'Planning.IsHighestPriorityLowNum'
	AND eeo.EquipmentClassName =  'Pre-Weigh - SiteWide'
	
SELECT	ProcessOrder	AS	PONum	    ,
		POPriority		AS	Priority    ,
		ProdId			AS	ProdId		,
		ProdCode		AS	Material	,  
		ProdDesc		AS	MaterialDesc,  
		LTRIM(STR(ForecastQty, 15, @iFixDecimals))		AS	TargetQty	,
		LTRIM(STR(ISNULL(DispensedQty, 0.0), 15, @iFixDecimals))	AS	DispenseQty ,
		UOM				AS	UOM			, 
		POStatus		AS	Status		, 
		DispensePUDesc	AS  DispenseStation
FROM	@POList
ORDER BY POPriority * CASE WHEN @PriorityLowToHigh = 1 THEN 1 ELSE -1 END, ProcessOrder
 
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_GetPOsToDispense] TO [public]
 
 
 
 
 
