 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RETU_GetReturnReasons
	
	Get a list of all phrases for "MPWS_ReturnReasons" datatype.
	
	Date			Version		Build	Author  
	05-Jul-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RETU_GetReturnReasons @ErrorCode OUTPUT, @ErrorMessage OUTPUT
 
SELECT @ErrorCode, @ErrorMessage
 
 
grant execute on dbo.spLocal_MPWS_RETU_GetReturnReasons to [comxclient]
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RETU_GetReturnReasons]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
SELECT 
	ph.Phrase_Id ReasonId,
	ph.Phrase_Value ReturnReason
FROM dbo.Data_Type dt
	JOIN dbo.Phrase ph ON ph.Data_Type_Id = dt.Data_Type_Id
WHERE dt.Data_Type_Desc = 'MPWS_ReturnReasons'
	AND ph.Active = 1
ORDER BY ph.Phrase_Order
 
IF @@ROWCOUNT > 0
BEGIN
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
END
ELSE
BEGIN
	SET @ErrorCode = -1;
	SET @ErrorMessage = 'No Return Reasons found';
END
 
 
 
