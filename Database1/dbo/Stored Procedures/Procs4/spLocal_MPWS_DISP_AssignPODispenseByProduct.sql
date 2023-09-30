 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_AssignPODispenseByProduct]
 
		@ProdId			INT ,
		@PUId			INT 
AS	


--declare 		@ProdId			INT =11258 ,
--		@PUId			INT =5631
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Set the DispenseStationId UDP to the pased in PUId of the BOMFIs that are 
-- not already assigned and have a valid status
/*


exec [dbo].[spLocal_MPWS_DISP_AssignPODispenseByProduct] 10355, 5631
 
 
*/
-- Date         Version Build Author  
-- 20-Nov-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-- 15-05-2017   001     002   Susan Lee (GE Digital) Added update count, added filter for PO status
-- 24-05-2017   001     003   Susan Lee (GE Digital) Changed UDP direct table joins to utilize fnLocal_MPWS_GetUDP
-- 02-06-2017   001     004   Susan Lee (GE Digital) Added filter for Preweigh path when checking PO status
-- 07-06-2017   001     005   Susan Lee (GE Digital) Updated error message when material is already assigned.
-- 09-06-2017   001     006   Susan Lee (GE Digital) Added error to check if station is already assigned a PO or Material
-- 09-12-2017   001     007   Susan Lee (GE Digital)  Get preweigh path from dispense unit
--													 Removed auto insert of missing UDP
--													 handle UDP joining to different types
--													 replace empty string with null for dispense station of BOMFI
-- 09-28-2017   001     008   Susan Lee (GE Digital)  Check for emptry string also when looking for already assigned PO or Material

-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
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
	StatusId				INT									NULL
)	
 
DECLARE	@tValidBOMFIStatus	TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	StatusId				INT							NULL
)	
 
DECLARE @UpdateCount	INT,
		@Rowcount		INT,
		@ProdCode		VARCHAR(50),
		@ClassName		VARCHAR(255),
		@DispenseType	VARCHAR(255),
		@PreweighPath	INT
 
----------------------------------------------------------------------------------------
-- Get material
----------------------------------------------------------------------------------------
SELECT	@ProdCode		=	Prod_Code
FROM	dbo.Products
WHERE	Prod_Id			=	@ProdId
 
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
-- Validate Material is not already assigned
----------------------------------------------------------------------------------------
 
 
SELECT @Rowcount = COUNT(*)
FROM	dbo.Property_Equipment_EquipmentClass PEC
		JOIN	dbo.PAEquipment_Aspect_SOAEquipment PAS
		ON		PEC.EquipmentId					= PAS.Origin1EquipmentId
		AND		PEC.Class						= @ClassName
		AND		PEC.Name						= 'DispenseMaterial'
WHERE PEC.Value = @ProdCode
 
IF @Rowcount > 0
BEGIN
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
		VALUES (-1, 'Material ' + @ProdCode + ' is already assigned.')
		SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
		RETURN
END
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
-- Get preweigh path
-------------------------------------------------------------------------------
SELECT @PreweighPath	= pep.Path_Id
	FROM	dbo.prdexec_paths		pep
	JOIN	dbo.Prod_Units_Base		pu	ON pu.pl_id = pep.pl_id
WHERE	pu.pu_id = @PUId
	
-------------------------------------------------------------------------------
--  Get the BOM Formulation Items for this Product that have the valid status
-- to be dispensed
-------------------------------------------------------------------------------
INSERT	@tBOMFIId (BOMFIId, StatusId)
		SELECT	BOMFI.BOM_Formulation_Item_Id, bstatus.Value
				FROM	dbo.Bill_Of_Material_Formulation_Item BOMFI
				JOIN	dbo.Production_Plan PP
				ON		PP.BOM_Formulation_Id = BOMFI.BOM_Formulation_Id AND pp.Path_id = @PreweighPath 
				JOIN	@tValidBOMFIStatus P_S	
				ON		P_S.StatusId = PP.PP_Status_Id
				CROSS APPLY dbo.fnLocal_MPWS_GetUDP(BOMFI.BOM_Formulation_Item_Id, 'BOMItemStatus',     'Bill_Of_Material_Formulation_Item') bstatus
				JOIN	@tValidBOMFIStatus S
				ON	 isnumeric(bstatus.Value) = 1 and	FLOOR(CAST(bstatus.Value AS float)	)
							= S.StatusId
			WHERE BOMFI.Prod_Id				= @ProdId
			
-------------------------------------------------------------------------------
--  Get their Dispense Station Id value
-------------------------------------------------------------------------------

UPDATE	T
	SET T.DispenseStationId		= NULLIF(LTRIM(RTRIM(dstation.Value)),'')
		FROM	@tBOMFIId T
		CROSS APPLY dbo.fnLocal_MPWS_GetUDP(T.BOMFIId, 'DispenseStationId',     'Bill_Of_Material_Formulation_Item') dstation

-------------------------------------------------------------------------------
-- Remove BOM Items already assigned to a station
-------------------------------------------------------------------------------	
DELETE	@tBOMFIId
		WHERE	DispenseStationId	IS NOT NULL

-------------------------------------------------------------------------------
-- Update the DispenseStationId UDP for the remaining BOMFIs
-------------------------------------------------------------------------------
UPDATE	TFV
		SET	TFV.Value	= CONVERT(VARCHAR(50),@PUId)
		FROM	dbo.Table_Fields_Values TFV
		JOIN	dbo.Table_Fields TV
		ON		TFV.Table_Field_Id	= TV.Table_Field_Id
		AND		TV.TableId = 28
		AND		TV.Table_Field_Desc	= 'DispenseStationId'
		JOIN	@tBOMFIId	T
		ON		TFV.KeyId		= CONVERT(INT,T.BOMFIId)
		AND		TFV.TableId		= 28
SET @UpdateCount = @@ROWCOUNT


 --if the UPDATE failed do an INSERT to create the UDP
--IF @UpdateCount = 0
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
 
IF		@UpdateCount = 0
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (-1, 'Could not find valid BOMs to assign to this station.')
ELSE
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (1, 'Success')
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_AssignPODispenseByProduct] TO [public]
 
 
 
 
 
 
