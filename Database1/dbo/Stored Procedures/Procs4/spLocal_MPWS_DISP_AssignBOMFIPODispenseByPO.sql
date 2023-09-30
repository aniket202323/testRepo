 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_AssignBOMFIPODispenseByPO]
		@PPId			INT,
		@PUId			INT
--WITH ENCRYPTION
AS	


-----------------------------------------------------------------------------
-- Set the BOMFIs .PU_Id to the passed in PUId of the BOMFIs that are 
-- not already assigned and have a valid status
/*
exec [dbo].[spLocal_MPWS_DISP_AssignBOMFIPODispenseByPO] 390780, 3372
 
 
*/
-- Date         Version Build	Author  
-- 20-May-2016	001		001		Chris Donnelly (GEIP)  Initial development
-- 10-Nov-2017	001		002		Susan Lee (GE Digital) filter BOMs for preweigh BOM	
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
INSERT	@tBOMFIId (BOMFIId, PU_Id, StatusFlag)
				SELECT	BOMFI.BOM_Formulation_Item_Id, ds.Value, 0
				FROM	dbo.Bill_Of_Material_Formulation_Item BOMFI
				JOIN	dbo.Production_Plan PP
				ON		BOMFI.BOM_Formulation_Id	= PP.BOM_Formulation_Id
				AND		PP.PP_Id					= @PPId
				JOIN	dbo.Prod_Units_Base bompu
				ON		bompu.PU_Id = bomfi.PU_Id
				JOIN	dbo.Prod_Units_Base disppu
				ON		disppu.PL_Id = bompu.PL_Id AND disppu.PU_Id = @PUId
				OUTER APPLY dbo.fnLocal_MPWS_GetUDP(BOMFI.BOM_Formulation_Item_Id, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds
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
		WHERE	PU_Id IS NOT NULL
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
 
UPDATE tfv
	SET Value = @PUId
	FROM dbo.Table_Fields_Values tfv
		JOIN dbo.Table_Fields tf ON tfv.Table_Field_Id = tf.Table_Field_Id
		JOIN dbo.Tables t ON tfv.TableId = t.TableId
			AND tf.TableId = t.TableId
		JOIN @tBOMFIId b ON tfv.KeyId = b.BOMFIId 
	WHERE tf.Table_Field_Desc = 'DispenseStationId'
		AND t.TableName = 'Bill_Of_Material_Formulation_Item'

 
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
 

 
