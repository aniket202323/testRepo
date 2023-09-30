 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_KittingBody
	
	This report is used to determine if a PO has been fully preweighed. 
	When the PO is fully dispensed this report provides a record of the dispenses 
	that must be kittted to deliver the complete PO to production.
	
	This sp returns body info for spLocal_MPWS_RPT_KittingHeader
	
	Date			Version		Build	Author  
	17-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
	11-Aug-2016		001			002		Susan Lee (GEIP)		return 2 tables
	19-Aug-2016		001			003		Jim Cameron				Split into 3, original sp to get data, _Grouping to get distinct groups and _Details to get the details for the groups
	
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_KittingBody_Grouping @ErrorCode OUTPUT, @ErrorMessage OUTPUT, null 
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_KittingBody_Grouping @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '20151120105909'
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_KittingBody_Grouping @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'PO19'
 
SELECT @ErrorCode, @ErrorMessage
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_KittingBody_Grouping]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ProcessOrder	VARCHAR(50)
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
---------------------------------------------------------------------------------------------
--  Declare variables
---------------------------------------------------------------------------------------------
DECLARE @tOutput TABLE
(
		Kit					varchar(50),				
		Carrier				varchar(50),			
		CarrierSection		varchar(50), 
		Material			varchar(50),			
		MaterialDesc		varchar(50),		
		TargetWgt			float,			
		DispensedWgt		float,		
		ContainerId			varchar(50),		
		ContainerWgt		float,		
		PGLotId				varchar(50)		
)
---------------------------------------------------------------------------------------------
--  Get data
---------------------------------------------------------------------------------------------
	
BEGIN TRY
 
	INSERT @tOutput
		EXEC dbo.spLocal_MPWS_RPT_KittingBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, @ProcessOrder
 
	---------------------------------------------------------------------------------------------
	--  Select Kit
	---------------------------------------------------------------------------------------------
	SELECT DISTINCT
			Kit,				
			Carrier,			
			CarrierSection	
	FROM @tOutput
		
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
	
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
