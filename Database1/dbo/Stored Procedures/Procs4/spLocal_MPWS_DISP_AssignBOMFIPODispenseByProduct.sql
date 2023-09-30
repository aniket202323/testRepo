 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_AssignBOMFIPODispenseByProduct]
		@ProdId			INT,
		@PUId			INT
AS	
-------------------------------------------------------------------------------
-- Set the BOMFIs .PU_Id to the passed in PUId of the BOMFIs that are 
-- not already assigned and have a valid status
/*
exec [dbo].[spLocal_MPWS_DISP_AssignBOMFIPODispenseByProduct] 6511, 3372
 
 
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
	PU_Id					INT									NULL,
	StatusId				INT									NULL
)	
 
DECLARE	@tValidBOMFIStatus	TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	StatusId				INT									NULL
)	
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
--  Get the BOM Formulation Items for this Product that have the valid status
-- to be dispensed
-------------------------------------------------------------------------------
INSERT	@tBOMFIId (BOMFIId, PU_Id, StatusId)
		SELECT	BOMFI.BOM_Formulation_Item_Id, BOMFI.PU_Id , TFV.Value
				FROM	dbo.Bill_Of_Material_Formulation_Item BOMFI
				JOIN	dbo.Table_Fields_Values TFV
				ON		BOMFI.BOM_Formulation_Item_Id= TFV.KeyId
				AND		BOMFI.Prod_Id				= @ProdId
				AND		TFV.TableId					= 28
				JOIN	dbo.Table_Fields TV
				ON		TFV.Table_Field_Id			= TV.Table_Field_Id
				AND		TV.Table_Field_Desc			= 'BOMItemStatus'	
				JOIN	@tValidBOMFIStatus S
				ON		TFV.Value					= S.StatusId
-------------------------------------------------------------------------------
-- Remove BOM Items already assigned to a station
-------------------------------------------------------------------------------		
DELETE	@tBOMFIId
		WHERE	PU_Id	IS NOT NULL
-------------------------------------------------------------------------------
-- Update the BIMFI.PU_ID for the remaining BOMFIs
-------------------------------------------------------------------------------
 
UPDATE tfv
	SET Value = @PUId
	FROM dbo.Table_Fields_Values tfv
		JOIN dbo.Table_Fields tf ON tfv.Table_Field_Id = tf.Table_Field_Id
		JOIN dbo.Tables t ON tfv.TableId = t.TableId
			AND tf.TableId = t.TableId
		JOIN @tBOMFIId b ON tfv.KeyId = b.BOMFIId 
	WHERE tf.Table_Field_Desc = 'DispenseStationId'
		AND t.TableName = 'Bill_Of_Material_Formulation_Item'
 
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
 
--UPDATE	BOMFI
--		SET	BOMFI.PU_Id	= @PUId
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
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_AssignBOMFIPODispenseByProduct] TO [public]
 
 
 
 
 
 
 
