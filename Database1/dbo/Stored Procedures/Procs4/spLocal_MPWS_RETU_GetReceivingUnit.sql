 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_RETU_GetReceivingUnit]
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(500)	OUTPUT,
		@ReceivingPUId	INT				OUTPUT,
		@ReceivingUnitPUDesc	VARCHAR(500)	OUTPUT,
		@Unit_Id		INT
AS	
 
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Get the receiving unit of the same area as the passed (dispense) unit
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500), @ReceivingPUId INT, @ReceivingUnitPUDesc VARCHAR(500)
exec spLocal_MPWS_RETU_GetReceivingUnit @ErrorCode OUTPUT, @ErrorMessage OUTPUT, @ReceivingPUId OUTPUT, @ReceivingUnitPUDesc OUTPUT, 3383
select @ErrorCode, @ErrorMessage, @ReceivingPUId, @ReceivingUnitPUDesc
*/
-- Date         Version Build Author  
-- 01-JUL-2016	001		001		Chris Donnelly (GE Digital)  Initial development	
 
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
DECLARE	@tOutput			TABLE
(
	Id					INT					IDENTITY(1,1)	NOT NULL,
	PU_Id				INT					NULL,
	PU_Desc				VARCHAR(50)			NULL
)
------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	1,
		@ErrorMessage	=	'Success'
-------------------------------------------------------------------------------
-- Get carrier section events
-------------------------------------------------------------------------------
INSERT INTO @tOutput
(PU_Id,PU_Desc)
	SELECT
		ru.PU_Id,
		ru.PU_Desc
		FROM dbo.Prod_Units_Base pu
			--Join dbo.Prod_Lines_Base pl on pl.PL_Id = pu.PL_Id
			Join dbo.Prod_Units_Base ru on ru.PL_Id = pu.PL_Id
				AND ru.PU_Desc LIKE 'PW%-Receiving'
		WHERE
			pu.PU_Id = @Unit_Id
 
------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
 
SELECT	
		@ReceivingPUId = PU_Id,
		@ReceivingUnitPUDesc = PU_Desc
	FROM @tOutput 
 
IF @ReceivingPUId IS NULL
	BEGIN
		SELECT	@ErrorCode		=	-1,
				@ErrorMessage	=	'Receiving Unit Not Found'
	END
 
 
 
