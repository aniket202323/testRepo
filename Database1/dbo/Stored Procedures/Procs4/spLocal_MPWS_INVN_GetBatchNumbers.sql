 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_INVN_GetBatchNumbers]
		@ErrorCode		INT				OUTPUT		,
		@ErrorMessage	VARCHAR(500)	OUTPUT		,
		@ProdId			INT		= NULL
--WITH ENCRYPTION
AS				
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Distinct list of raw material container inventory SAP batch numbers.
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_INVN_GetBatchNumbers @ErrorCode output, @ErrorMessage output,4692
select @ErrorCode, @ErrorMessage

*/
-- Date         Version Build Author  
-- 13-Nov-2017  001     001    Susan Lee (GE Digital)  Initial development
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE @tOutput TABLE
	(
		BatchNumber VARCHAR(255)
	)

-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	1,
		@ErrorMessage	=	'Initialized'
 
	
-------------------------------------------------------------------------------
-- Validate Parameters
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Get list of SAP Batch Numbers
------------------------------------------------------------------------------- 
INSERT INTO @tOutput VALUES ('ALL')

INSERT INTO @tOutput
SELECT	DISTINCT Result
FROM	dbo.Events				rmc		WITH (NOLOCK)
JOIN	dbo.Prod_Units_Base		rmcpu	WITH (NOLOCK)
	ON	rmcpu.PU_Id	 = rmc.PU_Id	
	AND rmcpu.Equipment_Type = 'Receiving Station'	
JOIN	dbo.Variables_Base		rmcv	WITH (NOLOCK)
	ON	rmcv.PU_Id = rmc.PU_Id
	AND rmcv.Test_Name = 'MPWS_INVN_SAP_LOT'
JOIN	dbo.Tests				rmct	WITH (NOLOCK)
	ON	rmct.Var_Id = rmcv.Var_Id
	AND	rmct.Result_On = rmc.[TimeStamp]
WHERE Result IS NOT NULL
	AND	( rmc.Applied_Product = @ProdId OR @ProdID IS NULL)
ORDER BY Result


-------------------------------------------------------------------------------
-- Return batch numbers
------------------------------------------------------------------------------- 
SELECT	* 
FROM	@tOutput

