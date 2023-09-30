 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_AssignPODispenseByPO]
 
		@PPId			INT ,
		@PUId			INT 
AS	
-------------------------------------------------------------------------------
-- Update DispenseStationId UDP for BOMFIs that are not already assigned and 
-- that have a valid status
/*
 
exec [dbo].[spLocal_MPWS_DISP_AssignPODispenseByPO] 9771, 4321
 
*/
-- Date         Version Build Author  
-- 20-Nov-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-- 08-Jun-2016	001		002		Jim Cameron				Added check at beginning to see if another po is already assigned to the requested dispense station.
-- 22-May-2017  001     003		Susan Lee (GE Digital)  Changed Dispense station check from setting Assigned bit to updating PUId of assigned dispense station.
-- 07-Jun-2017  001     004     Susan Lee (GE Digital)	Updated error message for PO that is already assigned to a station.
-- 09-Jun-2017  001     005     Susan Lee (GE Digital)  Added error to check if station is already assigned a PO or Material
-- 09-28-2017   001     008   Susan Lee (GE Digital)	Check for emptry string also when looking for already assigned PO or Material
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
SET NOCOUNT ON;
 
DECLARE	@tFeedback			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ErrorCode				INT									NULL,
	ErrorMessage			VARCHAR(255)						NULL
)
 
DECLARE	@tBOMFIId			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	BOMFIId					INT									NULL,
	DispenseStationId		VARCHAR(255)						NULL,
	StatusId				INT									NULL,
	StatusFlag				INT									NULL
)	
 
DECLARE	@tValidBOMFIStatus	TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	StatusId				INT									NULL
)
 
DECLARE @bomfi TABLE
(
	ProcessOrder	VARCHAR(50),
	BOMFI_Id		INT,
	PUId			INT
)
 
DECLARE
	@ExistingPO		VARCHAR(50),
	@Rowcount		INT,
	@PO				VARCHAR(50),
	@ClassName		VARCHAR(255),
	@DispenseType	VARCHAR(255)
 
----------------------------------------------------------------------------------------
-- Get process order
----------------------------------------------------------------------------------------
SELECT	@PO		=	Process_Order
FROM	dbo.Production_Plan
WHERE	PP_Id	=	@PPId
 
----------------------------------------------------------------------------------------
-- Get class name
----------------------------------------------------------------------------------------
 
EXEC	dbo.spLocal_MPWS_GENL_GetSiteProperty NULL,NULL, 
		@ClassName OUTPUT,  'Class Names.Dispense'	
 
----------------------------------------------------------------------------------------
-- Validate Station is not assigned
----------------------------------------------------------------------------------------
 
SELECT @DispenseType = CONVERT(VARCHAR(255),PEC.Value)
FROM	dbo.Property_Equipment_EquipmentClass PEC
		JOIN	dbo.PAEquipment_Aspect_SOAEquipment PAS
		ON		PEC.EquipmentId					= PAS.Origin1EquipmentId
		JOIN	dbo.Prod_Units_Base pu
		ON		pas.PU_Id = pu.PU_Id		
		AND		PEC.Class						= @ClassName
		AND		PEC.Name						= 'DispenseType'
		AND		pas.PU_Id						= @PUId
 
IF @DispenseType IS NOT NULL AND LTRIM(RTRIM(@DispenseType)) <> ''
BEGIN
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
		VALUES (-9, 'This station is already assigned by ' + @DispenseType)
		SELECT	Id						Id,
				ErrorCode				ErrorCode,
				ErrorMessage			ErrorMessage
		FROM	@tFeedback
		RETURN
END
----------------------------------------------------------------------------------------
-- Validate PO is not already assigned
----------------------------------------------------------------------------------------
 
SELECT @Rowcount = COUNT(*)
FROM	dbo.Property_Equipment_EquipmentClass PEC 
		JOIN	dbo.PAEquipment_Aspect_SOAEquipment PAS
		ON		PEC.EquipmentId					= PAS.Origin1EquipmentId
		AND		PEC.Class						= @ClassName
		AND		PEC.Name						= 'DispensePO'
WHERE PEC.Value = @PO
 
IF @Rowcount > 0
BEGIN
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
		VALUES (-1, 'PO ' + @PO + ' is already assigned.')
		SELECT	Id						Id,
				ErrorCode				ErrorCode,
				ErrorMessage			ErrorMessage
		FROM	@tFeedback
		RETURN
END
 
-------------------------------------------------------------------------------------------------------------------------
-- get every po released or dispensing that IS NOT the requested po yet on same path
-- because table_fields_values.Value has no index, use a table var for bomfi id's to limit the udp's we need to look up.
--------------------------------------------------------------------------------------------------------------------------
INSERT @bomfi (ProcessOrder, BOMFI_Id, PUId)
	SELECT
		pp.Process_Order,
		bomfi.BOM_Formulation_Item_Id,
		ds.Value
	FROM dbo.Production_Plan pp
		JOIN dbo.Production_Plan_Statuses pps ON pp.PP_Status_Id = pps.PP_Status_Id
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds
	WHERE pp.Path_Id = (SELECT Path_Id FROM dbo.Production_Plan WHERE PP_Id = @PPId)	-- get PO's on same path
		AND pp.PP_Id <> @PPId															-- but exclude the requested one
		AND pps.PP_Status_Desc IN ('Released', 'Dispensing')
 
 
SELECT @ExistingPO = (SELECT TOP 1 ProcessOrder FROM @bomfi WHERE PUId = @PUId);
 
IF @ExistingPO IS NULL
BEGIN
 
	-------------------------------------------------------------------------------
	--  Populate the BOMFI status table with the valid BOMFI statuses that can be
	-- assigned to a station
	-------------------------------------------------------------------------------
	INSERT	@tValidBOMFIStatus (StatusId)
			SELECT	PP_Status_Id
					FROM	dbo.Production_Plan_Statuses
					WHERE	PP_Status_Desc = 'Released'
					
	INSERT	@tValidBOMFIStatus (StatusId)
			SELECT	PP_Status_Id
					FROM	dbo.Production_Plan_Statuses
					WHERE	PP_Status_Desc = 'Dispensing'				
	-------------------------------------------------------------------------------
	--  Get the BOM Formulation Items for this bom formulation
	-------------------------------------------------------------------------------
	INSERT	@tBOMFIId (BOMFIId, StatusFlag)
			SELECT	BOMFI.BOM_Formulation_Item_Id, 0
					FROM	dbo.Bill_Of_Material_Formulation_Item BOMFI
					JOIN	dbo.Production_Plan PP
					ON		BOMFI.BOM_Formulation_Id	= PP.BOM_Formulation_Id
					AND		PP.PP_Id					= @PPId
	-------------------------------------------------------------------------------
	--  Get their Dispense Station Id value
	-------------------------------------------------------------------------------
	UPDATE	T
			SET	T.DispenseStationId		= TFV.Value
			FROM	@tBOMFIId T
			JOIN	dbo.Table_Fields_Values TFV
			ON		T.BOMFIId			= TFV.KeyId
			AND		TFV.TableId			= 28
			JOIN	dbo.Table_Fields TV
			ON		TFV.Table_Field_Id	= TV.Table_Field_Id
			AND		TV.Table_Field_Desc	= 'DispenseStationId'
	-------------------------------------------------------------------------------
	--  Get the BOM Formulation Id status value
	-------------------------------------------------------------------------------
	UPDATE	T
			SET	T.StatusId				= TFV.Value
			FROM	@tBOMFIId T
			JOIN	dbo.Table_Fields_Values TFV
			ON		T.BOMFIId			= TFV.KeyId
			AND		TFV.TableId			= 28
			JOIN	dbo.Table_Fields TV
			ON		TFV.Table_Field_Id	= TV.Table_Field_Id
			AND		TV.Table_Field_Desc	= 'BOMItemStatus'		
	-------------------------------------------------------------------------------
	-- Remove BOM Items already assigned to a station
	-------------------------------------------------------------------------------		
	DELETE	@tBOMFIId
			WHERE	DispenseStationId	IS NOT NULL AND DispenseStationId <> ''
	-------------------------------------------------------------------------------
	-- Remove BOM Items with status <> than valid ones
	-------------------------------------------------------------------------------		
	UPDATE	T
			SET	T.StatusFlag = 1
			FROM	@tBOMFIId T
			JOIN	@tValidBOMFIStatus S
			ON		T.StatusId	= S.StatusId
			
	DELETE	@tBOMFIId
			WHERE	StatusFlag = 0
 
 
	-------------------------------------------------------------------------------
	-- Update the DispenseStationId UDP for the remaining BOMFIs
	-------------------------------------------------------------------------------
	UPDATE	TFV
			SET	TFV.Value	= CAST(@PUId AS VARCHAR)
			FROM	dbo.Table_Fields_Values TFV
			JOIN	@tBOMFIId	T
			ON		TFV.KeyId		= T.BOMFIId
			AND		TFV.TableId		= 28
			JOIN	dbo.Table_Fields TV
			ON		TFV.Table_Field_Id	= TV.Table_Field_Id
			AND		TV.Table_Field_Desc	= 'DispenseStationId'
 
	---- if the UPDATE failed do an INSERT to create the UDP
	--IF @@ROWCOUNT = 0
	--BEGIN
 
	--	;WITH ids AS
	--	(
	--		SELECT
	--			t.TableId,
	--			tf.Table_Field_Id
	--		FROM dbo.Table_Fields tf
	--			JOIN dbo.Tables t ON tf.TableId = t.TableId
	--		WHERE tf.Table_Field_Desc = 'DispenseStationId'
	--			AND t.TableName = 'Bill_Of_Material_Formulation_Item'
	--	)
	--	INSERT dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
	--		SELECT b.BOMFIId, ids.Table_Field_Id, ids.TableId, @PUId
	--		FROM @tBOMFIId b
	--			CROSS APPLY ids
 
	--END
 
	IF		@@ROWCOUNT = 0
			INSERT	@tFeedback (ErrorCode, ErrorMessage)
					VALUES (-2, 'Could not find valid BOMs to assign to this station.')
	ELSE
			INSERT	@tFeedback (ErrorCode, ErrorMessage)
					VALUES (1, 'Success')
					
END
ELSE
BEGIN
 
	INSERT	@tFeedback (ErrorCode, ErrorMessage)
		VALUES (-3, 'PO ' + @ExistingPO + ' is already assigned to this station.')
 
END
 
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_AssignPODispenseByPO] TO [public]
 
 
 
 
 
