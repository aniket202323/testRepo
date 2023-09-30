CREATE Procedure dbo.spSDK_DeleteTransaction
 	 @TransactionHandle int,
 	 @UserId int 
AS
-- Return Status
--
-- 0 = Success
-- 2 = Already Approved
DECLARE 	 @ApprovedOn 	 DATETIME
SELECT 	 @ApprovedOn = Approved_On
 	 FROM 	 Transactions
 	 WHERE 	 Trans_Id = @TransactionHandle
IF 	 @ApprovedOn IS NOT NULL RETURN(2)
--Call EM sp To Drop Transaction
EXECUTE 	 spEM_DropTransaction @TransactionHandle, 1
RETURN(0)
