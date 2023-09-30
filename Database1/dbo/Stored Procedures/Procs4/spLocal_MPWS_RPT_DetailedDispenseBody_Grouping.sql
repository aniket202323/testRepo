 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_DetailedDispenseBody_Grouping
	
	This report is used to determine if a PO has been fully preweighed. 
	When the PO is fully dispensed this report provides a record of the dispenses 
	that must be kittted to deliver the complete PO to production.
	
	This sp returns report body grouping info for spLocal_MPWS_RPT_DetailedDispenseHeader
	
	Date			Version		Build	Author  
	31-May-2016		001			001		Jim Cameron (GEIP)		Initial development	PW01DS01-Scale01PW01D01-Scale01
	19-Aug-2016		001			002		Jim Cameron				Split into 3, original sp to get data, _Grouping to get distinct groups and _Details to get the details for the groups
    23-Oct-2017     001			004		Susan Lee (GE Digital)	Remove DispenseEndDT, rename DispenseStartDT 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_DetailedDispenseBody_Grouping @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'Unassigned'
--EXEC dbo.spLocal_MPWS_RPT_DetailedDispenseBody_Grouping @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '20151113141739'
 
SELECT @ErrorCode, @ErrorMessage
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_DetailedDispenseBody_Grouping]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ProcessOrder	VARCHAR(50)
--WITH ENCRYPTION 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
---------------------------------------------------------------------------------------------
--  Declare variables
---------------------------------------------------------------------------------------------
 
DECLARE @tOutput TABLE
(
	BOMFIId					int,
	Material				varchar(50),
	MaterialDesc			varchar(50),
	TargetWeight			float,
	TotalDispWgt			float,
	BOMFIStatus				varchar(50),
	DispenseContainerId		varchar(50),
	DispenseContainerWeight float,
	DispenseTareWeight		float,
	UOM						varchar(50),
	MaterialLotId			varchar(50),
	DispenseUser			varchar(50),
	VerifierUser			varchar(50),
	DispenseStation			varchar(50),
	DispenseScale			varchar(50),
	DispenseMethod			varchar(50),
	DispenseTime			datetime
)
 
---------------------------------------------------------------------------------------------
--  Get data
---------------------------------------------------------------------------------------------
BEGIN TRY
 
	INSERT @tOutput
		EXEC dbo.spLocal_MPWS_RPT_DetailedDispenseBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, @ProcessOrder
 
-------------------------------------------------------------------------------------------
--  Select the material for grouping
-------------------------------------------------------------------------------------------
	SELECT DISTINCT
		@ProcessOrder ProcessOrder,
		BOMFIId,
		Material,
		MaterialDesc,
		TargetWeight,
		CAST(TotalDispWgt AS DECIMAL(10,3)) as TotalDispWgt,
		BOMFIStatus
	FROM @tOutput
	GROUP BY 
		BOMFIId,
		Material,
		MaterialDesc,
		TargetWeight,
		TotalDispWgt,
		BOMFIStatus
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
		
END TRY
 
BEGIN CATCH
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
END CATCH
 
