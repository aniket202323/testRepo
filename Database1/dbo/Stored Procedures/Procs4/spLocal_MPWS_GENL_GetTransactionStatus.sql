 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_GENL_GetTransactionStatus
	
	Sproc to get transaction info
 
	Date			Version		Build	Author  
	16-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
EXEC dbo.spLocal_MPWS_GENL_GetTransactionStatus 1
EXEC dbo.spLocal_MPWS_GENL_GetTransactionStatus 2400
 
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_GENL_GetTransactionStatus]
	@TransactionId	INT
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
SELECT
	ProcessedDate,
	ErrorCode,
	ErrorMessage,
	OutField01,
	OutField02,
	OutField03,
	OutField04,
	OutField05
FROM dbo.Local_MPWS_GENL_Transactions
WHERE Id = @TransactionId
  
 
