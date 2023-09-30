 
 
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
EXEC dbo.spLocal_MPWS_RPT_Inventory_Grouping @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '', ''
SELECT @ErrorCode, @ErrorMessage
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_Inventory_Grouping @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '', 'rm03'
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_Inventory_Grouping @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'inventory', ''
 
SELECT @ErrorCode, @ErrorMessage
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_Inventory_Grouping]
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
 
	INSERT INTO @tOutput
		EXEC dbo.spLocal_MPWS_RPT_Inventory @ErrorCode OUTPUT, @ErrorMessage OUTPUT, @RMCStatus, @Material
	
	---------------------------------------------------------------------------------------------
	-- Select material information
	---------------------------------------------------------------------------------------------
 
	SELECT	DISTINCT
			Material,
			MaterialDesc
	FROM @tOutput
	ORDER BY Material
	
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
 
 
