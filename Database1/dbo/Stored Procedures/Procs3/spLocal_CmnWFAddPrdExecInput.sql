CREATE PROCEDURE  [dbo].[spLocal_CmnWFAddPrdExecInput]
@PPId								int,
@OG									varchar(30),
@ULINPUID							int

AS
SET NOCOUNT ON 

DECLARE	
@TableId							int,
@TableFieldId						int,
@TableFieldIdSF						int,
@TableFieldIdSFS					int,
@TableFieldIdWMS					int,
@TableFieldIdRaC					int,
@TableFieldIdSCI					int,
@TableFieldIdIBOMDL					int,
@TableFieldIdCT						int,
@TableFieldIdLO						int,
@TableFieldIdSS						int,
@MinPuid							int,
@InputId							int,
@EventSubtypeId						int,
@InputOrder							int,
@InputName							varchar(50),
@PEISID								int

DECLARE		@ProductionPoint	TABLE (
puid								int
)



---------------------------------------------------------------------------------------
--Get UDP info constant
---------------------------------------------------------------------------------------
SET @TableId		= (SELECT tableid FROM dbo.tables WHERE tableName = 'PrdExec_Inputs')
SET @TableFieldId	= (SELECT table_Field_id FROM dbo.table_fields WHERE table_field_desc = 'Origin Group' AND tableid = @TableId)
SET @TableFieldIdSF	= (SELECT table_Field_id FROM dbo.table_fields WHERE table_field_desc = 'RMScrapFactor' AND tableid = @TableId)
SET @TableFieldIdSFS= (SELECT table_Field_id FROM dbo.table_fields WHERE table_field_desc = 'UseRMScrapFactor' AND tableid = @TableId)
SET @TableFieldIdWMS = (SELECT table_Field_id FROM dbo.table_fields WHERE table_field_desc = 'PE_WMS_System' AND tableid = @TableId)
SET @TableFieldIdRaC= (SELECT table_Field_id FROM dbo.table_fields WHERE table_field_desc = 'ReportAsConsumption' AND tableid = @TableId)
SET @TableFieldIdSCI= (SELECT table_Field_id FROM dbo.table_fields WHERE table_field_desc = 'ScannerCheckIn' AND tableid = @TableId)
SET @TableFieldIdIBOMDL= (SELECT table_Field_id FROM dbo.table_fields WHERE table_field_desc = 'IsBOMPLCDownload' AND tableid = @TableId)
SET @TableFieldIdCT= (SELECT table_Field_id FROM dbo.table_fields WHERE table_field_desc = 'ConsumptionType' AND tableid = @TableId)
SET @TableFieldIdLO= (SELECT table_Field_id FROM dbo.table_fields WHERE table_field_desc = 'LabelOrdering' AND tableid = @TableId)
SET @TableFieldIdSS= (SELECT table_Field_id FROM dbo.table_fields WHERE table_field_desc = 'SafetyStock' AND tableid = @TableId)

SET @EventSubtypeId = (SELECT event_subtype_id FROM dbo.event_subtypes WHERE event_subtype_desc = 'Pallet_Unit')

--Get out if the table field id is not found
IF @TableFieldId IS NULL
	RETURN

---------------------------------------------------------------------------------------
--Get production point(s) for the PO
---------------------------------------------------------------------------------------
INSERT @ProductionPoint (puid)
SELECT ppu.pu_id
FROM dbo.production_plan pp			WITH(NOLOCK)
JOIN dbo.prdExec_Path_units  ppu		WITH(NOLOCK)	ON pp.path_id = ppu.path_id
															AND ppu.is_production_point = 1
WHERE pp.pp_id = @PPId

IF NOT EXISTS(SELECT 1 FROM @ProductionPoint)
	RETURN	

---------------------------------------------------------------------------------------
--Create Raw Material Inputs
---------------------------------------------------------------------------------------
--Loop thru all production point
SET @MinPuid = (SELECT MIN(puid) FROM @ProductionPoint)
WHILE @MinPuid IS NOT NULL
BEGIN

	SET @InputId = (SELECT pei.pei_id
					FROM dbo.prdExec_Inputs pei		WITH(NOLOCK) 
					JOIN dbo.table_fields_values tfv		WITH(NOLOCK)	ON tfv.keyid = pei.pei_id
																			AND tfv.table_field_id = @TableFieldId
																			AND tfv.value = @OG
					WHERE pei.pu_id = @minpuid
					)

	--Create a new input only if there is not an existing one
	IF @InputId IS NULL
	BEGIN
		SET @InputOrder = (SELECT COUNT(1) + 1 FROM dbo.prdExec_Inputs WHERE pu_id = @MinPuid)
		SET @InputName = 'Input_' + @OG
		INSERT dbo.prdExec_Inputs (event_subtype_id, Input_Name, Input_order, Lock_Inprogress_input, pu_id)
		VALUES(@EventSubtypeId,@InputName,@InputOrder,0,@MinPuid)
		SET  @InputId = (SELECT Scope_identity())
		--SELECT @InputId = (SELECT max(pei_id) FROM dbo.prdExec_Inputs)



				--SET OG UDP for that Input
		INSERT dbo.Table_Fields_Values (keyId, table_field_id, tableId, value)
		VALUES (@InputId, @TableFieldId, @TableId, @OG)

		INSERT dbo.Table_Fields_Values (keyId, table_field_id, tableId, value)
		VALUES (@InputId, @TableFieldIdSF, @TableId, 0)

		INSERT dbo.Table_Fields_Values (keyId, table_field_id, tableId, value)
		VALUES (@InputId, @TableFieldIdSFS, @TableId, 0)

		--WMS Managed
		INSERT dbo.Table_Fields_Values (keyId, table_field_id, tableId, value)
		VALUES (@InputId, @TableFieldIdWMS, @TableId, 0)

		--Report as consumption
		INSERT dbo.Table_Fields_Values (keyId, table_field_id, tableId, value)
		VALUES (@InputId, @TableFieldIdRaC, @TableId, 0)

		--ScanerCheckIn
		INSERT dbo.Table_Fields_Values (keyId, table_field_id, tableId, value)
		VALUES (@InputId, @TableFieldIdSCI, @TableId, 0)
		
		--IsBOM PLC DOWNLoad
		INSERT dbo.Table_Fields_Values (keyId, table_field_id, tableId, value)
		VALUES (@InputId, @TableFieldIdIBOMDL, @TableId, 0)

		--Consumption type
		INSERT dbo.Table_Fields_Values (keyId, table_field_id, tableId, value)
		VALUES (@InputId, @TableFieldIdCT, @TableId, 1)

		--Label ordering
		INSERT dbo.Table_Fields_Values (keyId, table_field_id, tableId, value)
		VALUES (@InputId, @TableFieldIdLO, @TableId, 0)

		--SafetyStock
		INSERT dbo.Table_Fields_Values (keyId, table_field_id, tableId, value)
		VALUES (@InputId, @TableFieldIdSS, @TableId, 0)

		--set Input source for that new input
		INSERT dbo.prdexec_input_sources (pei_id, pu_id)
		VALUES (@InputId, @ULINPUID)
		SET  @PEISID =(SELECT Scope_identity())

		--Set production Status for the new input source
		INSERT dbo.prdexec_input_source_data (peis_id, valid_status)
		SELECT @PEISID,prodStatus_id FROM dbo.Production_status WHERE ProdStatus_Desc IN ('Delivered','Checked In','Running')
	END

	SET @MinPuid = (SELECT MIN(puid) FROM @ProductionPoint WHERE puid > @MinPuid)
END

SET NOCOUNT OFF