 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_Inventory
	
	If query contains any results it should return Success and the table should get 
	raw material container (inventory) information for either the specified status 
	OR specified material.  
	
	Sort by Material, SAPLotId, Container Id.
	
	
	Date			Version		Build	Author  
	21-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
	11-Aug-2016		001			002		Susan Lee (GEIP)		Update to return 2 tables, first table to group by material
	19-Aug-2016		001			003		Jim Cameron				Split into 3, original sp to get data, _Grouping to get distinct groups and _Details to get the details for the groups
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_Inventory @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '', ''
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_Inventory @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '', 'rm03'
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_Inventory @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'inventory', ''
 
SELECT @ErrorCode, @ErrorMessage
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_Inventory]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@RMCStatus		VARCHAR(50),
	@Material		VARCHAR(50)
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
---------------------------------------------------------------------------------------------
--  Declare variables
---------------------------------------------------------------------------------------------
 
DECLARE @tOutput TABLE
(
		Material		varchar(50),
		MaterialDesc	varchar(50),
		SAPLotId		varchar(50),
		ContainerId		varchar(50),
		ContainerStatus	varchar(50),
		QualityStatus	varchar(50),
		Location		varchar(50),
		Quantity		float,
		UOM				varchar(50)
)
---------------------------------------------------------------------------------------------
--  Get Data
---------------------------------------------------------------------------------------------
 
BEGIN TRY
	
	SELECT
		p.Prod_Code Material,
		p.Prod_Desc MaterialDesc,
		MPWS_INVN_SAP_LOT SAPLotId,
		ContainerId,
		ContainerStatus,
		MPWS_INVN_QA_STATUS QualityStatus,
		Location,
		InventoryQty Quantity,
		MPWS_INVN_RMC_UOM UOM
	FROM (
			SELECT
				e.Applied_Product Prod_Id,
				e.Event_Num ContainerId,
				ps.ProdStatus_Desc ContainerStatus,
				ul.Location_Desc Location,
				ed.Final_Dimension_X InventoryQty,
				v.Test_Name,
				t.Result
			FROM dbo.Events e
				JOIN dbo.Event_Details ed ON e.Event_Id = ed.Event_Id
				JOIN dbo.Prod_Units_Base pu ON e.PU_Id = pu.PU_Id
				JOIN dbo.Production_Status ps ON e.Event_Status = ps.ProdStatus_Id
				JOIN dbo.Unit_Locations ul ON ed.Location_Id = ul.Location_Id
					AND e.PU_Id = ul.PU_Id
				JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id 
				LEFT JOIN dbo.Tests t ON t.Var_Id = v.Var_Id 
					AND t.Result_On = e.[Timestamp]
			WHERE pu.PU_Desc LIKE '%Receiving%'
				AND v.Test_Name IN ('MPWS_INVN_SAP_LOT', 'MPWS_INVN_QA_STATUS', 'MPWS_INVN_RMC_UOM')
				AND (ps.ProdStatus_Desc = @RMCStatus OR ISNULL(@RMCStatus, '') = '')
		) a
		PIVOT (MAX(a.Result) FOR a.Test_Name IN ([MPWS_INVN_SAP_LOT], [MPWS_INVN_QA_STATUS], [MPWS_INVN_RMC_UOM])) pvt
		JOIN dbo.Products_Base p ON pvt.Prod_Id = p.Prod_Id
	WHERE (p.Prod_Code = @Material OR ISNULL(@Material, '') = '')
	ORDER BY Material, SAPLotId, ContainerId
	
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrorCode = 1;
		SET @ErrorMessage = 'Success';
	END
	ELSE
	BEGIN
		SET @ErrorCode = -1;
		SET @ErrorMessage = 'No Items found';
	END
	
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
