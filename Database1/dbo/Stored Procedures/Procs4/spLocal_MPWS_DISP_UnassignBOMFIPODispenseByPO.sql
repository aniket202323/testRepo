 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_UnassignBOMFIPODispenseByPO]
		@PPId			INT,
		@PUId			INT
AS	
-------------------------------------------------------------------------------
-- Set the BOMFIs .PU_Id to NULL for BOMFIs that are assigned to this PUId
-- and belong to the passed PO
/*
exec [dbo].[spLocal_MPWS_DISP_UnassignBOMFIPODispenseByPO] 390785, 3372
 
 
*/
-- Date         Version Build	Author  
-- 20-May-2016	001		001		Chris Donnelly (GEIP)  Initial development	
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
-------------------------------------------------------------------------------
--  Populate the BOMFI status table with the valid BOMFI statuses that can be
-- unassigned to a station
-------------------------------------------------------------------------------
INSERT	@tValidBOMFIStatus (StatusId)
		SELECT	PP_Status_Id
				FROM	dbo.Production_Plan_Statuses		WITH (NOLOCK)
				WHERE	PP_Status_Desc = 'Released'
				
INSERT	@tValidBOMFIStatus (StatusId)
		SELECT	PP_Status_Id
				FROM	dbo.Production_Plan_Statuses		WITH (NOLOCK)
				WHERE	PP_Status_Desc = 'Dispensing'				
-------------------------------------------------------------------------------
--  Get the BOM Formulation Items for this bom formulation with valid status
--  that are associated to the passed in dispense station
-------------------------------------------------------------------------------
 
--INSERT	@tBOMFIId (BOMFIId)
--		SELECT	BOMFI.BOM_Formulation_Item_Id
--				FROM	dbo.Bill_Of_Material_Formulation_Item BOMFI	WITH (NOLOCK)
--				JOIN	dbo.Production_Plan PP						WITH (NOLOCK)
--				ON		BOMFI.BOM_Formulation_Id	= PP.BOM_Formulation_Id
--				AND		PP.PP_Id					= @PPId
--				AND		BOMFI.PU_Id					= @PUId
--				JOIN	dbo.Table_Fields_Values TFV					WITH (NOLOCK)
--				ON		BOMFI.BOM_Formulation_Item_Id= TFV.KeyId					-- <==== bomfi id can't compare with status_id
--				AND		TFV.TableId					= 28
--				JOIN	dbo.Table_Fields TV							WITH (NOLOCK)
--				ON		TFV.Table_Field_Id			= TV.Table_Field_Id
--				AND		TV.Table_Field_Desc			= 'BOMItemStatus'
--				JOIN	@tValidBOMFIStatus S
--				ON		TFV.Value					= S.StatusId
				
INSERT @tBOMFIId (BOMFIId)
	SELECT DISTINCT
		bomfi.BOM_Formulation_Item_Id
	FROM dbo.Production_Plan pp
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		CROSS APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds
	WHERE pp.PP_Id = @PPId
		AND ds.Value = @PUId
 
-------------------------------------------------------------------------------
-- Update the BIMFI.PU_ID to NULL for the remaining BOMFIs
-------------------------------------------------------------------------------
 
UPDATE tfv
	SET Value = NULL
	FROM dbo.Table_Fields_Values tfv
		JOIN dbo.Table_Fields tf ON tfv.Table_Field_Id = tf.Table_Field_Id
		JOIN dbo.Tables t ON tfv.TableId = t.TableId
			AND tf.TableId = t.TableId
		JOIN @tBOMFIId b ON tfv.KeyId = b.BOMFIId 
	WHERE tf.Table_Field_Desc = 'DispenseStationId'
		AND t.TableName = 'Bill_Of_Material_Formulation_Item'
 
--UPDATE	BOMFI
--		SET	BOMFI.PU_Id	= NULL
--		FROM	dbo.Bill_Of_Material_Formulation_Item BOMFI		WITH (NOLOCK)
--		JOIN	@tBOMFIId	T
--		ON		BOMFI.BOM_Formulation_Item_Id	= T.BOMFIId
 
IF		@@ROWCOUNT = 0
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (-1, 'No Bill Of Material Formulation Items were updated')
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
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_UnassignBOMFIPODispenseByPO] TO [public]
 
 
 
 
 
 
 
