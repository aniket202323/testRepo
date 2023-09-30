 
 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_UnassignBOMFIPODispenseByProduct]
		@ProdId			INT,
		@PUId			INT
AS	
-------------------------------------------------------------------------------
-- Set the BOMFIs .PU_Id to NULL for BOMFIs for the passed in material that 
-- are assigned to this stationId
/*
exec [dbo].[spLocal_MPWS_DISP_UnassignBOMFIPODispenseByProduct] 6511, 3372
 
 
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
	BOMFIId					INT									NULL
)	
 
DECLARE	@tValidBOMFIStatus	TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	StatusId				INT									NULL
)	
 
DECLARE @paths TABLE
(
	Path_Id	INT
);
 
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
--  Get the BOM Formulation Items for this Product that have the valid status
-- to be dispensed and are associated with this station Id
-------------------------------------------------------------------------------
--INSERT	@tBOMFIId (BOMFIId)
--		SELECT	BOMFI.BOM_Formulation_Item_Id
--				FROM	dbo.Bill_Of_Material_Formulation_Item BOMFI	WITH (NOLOCK)
--				JOIN	dbo.Table_Fields_Values TFV					WITH (NOLOCK)
--				ON		BOMFI.BOM_Formulation_Item_Id	= TFV.KeyId					-- <==== bomfi id can't compare with status_id
--				AND		BOMFI.Prod_Id				= @ProdId
--				AND		BOMFI.PU_Id					= @PUId
--				AND		TFV.TableId					= 28
--				JOIN	dbo.Table_Fields TV							WITH (NOLOCK)
--				ON		TFV.Table_Field_Id			= TV.Table_Field_Id
--				AND		TV.Table_Field_Desc			= 'BOMItemStatus'	
--				JOIN	@tValidBOMFIStatus S
--				ON		TFV.Value					= S.StatusId	
 
INSERT @paths
	SELECT DISTINCT
		pep.Path_Id
	FROM dbo.Prdexec_Paths pep
		JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
		JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
	WHERE d.Dept_Desc = 'Pre-Weigh';
 
INSERT @tBOMFIId (BOMFIId)
	SELECT DISTINCT
		bomfi.BOM_Formulation_Item_Id
	FROM dbo.Bill_Of_Material_Formulation_Item bomfi
		JOIN dbo.Production_Plan pp ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		CROSS APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds
	WHERE bomfi.Prod_Id = @ProdId
		AND pp.Path_Id IN (SELECT Path_Id FROM @paths)
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
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_UnassignBOMFIPODispenseByProduct] TO [public]
 
 
 
 
 
 
 
