CREATE PROCEDURE dbo.spSDK_CreateTransaction
 	 @UserId 	  	  	  	  	 INT,
 	 @TransName 	  	  	  	 nvarchar(100) 	 OUTPUT,
 	 @TransId 	  	  	  	  	 INT  	  	  	  	 OUTPUT 
AS
-- Return Status
-- 	  	 0 = Success
-- 	  	 2 = Create Failed
DECLARE 	 @GroupId 	  	  	  	 INT,
 	  	  	 @CommentId 	  	  	 INT,
 	  	  	 @Orig_TransName 	 nvarchar(100),
 	  	  	 @Count 	  	  	  	 INT
IF @TransName IS NULL
BEGIN
 	 SELECT 	 @TransName = 'SDK: ' + CONVERT(nvarchar(25), dbo.fnServer_CmnGetDate(getUTCdate()), 121)
END
SELECT 	 @TransId = NULL,
 	  	  	 @Orig_TransName = @TransName,
 	  	  	 @Count = 0
SELECT 	 @TransId = Trans_Id
 	 FROM 	 Transactions
 	 WHERE 	 Trans_Desc = @TransName
WHILE 	 @TransId IS NOT NULL AND @Count < 1000
BEGIN
 	 SELECT 	 @Count = @Count + 1
 	 SELECT 	 @TransName = @Orig_TransName + ':' + CONVERT(nvarchar(25), @Count)
 	 SELECT 	 @TransId = NULL
 	 SELECT 	 @TransId = Trans_Id
 	  	 FROM 	 Transactions
 	  	 WHERE 	 Trans_Desc = @TransName
END
IF @TransId IS NOT NULL RETURN(3)
--Call EM sp To Add Transaction
EXECUTE 	 spEM_CreateTransaction 
 	 @TransName, 
 	 NULL, 
 	 1, 
 	 NULL, 
 	 @UserId, 
 	 @TransId OUTPUT
IF 	 @TransId IS NULL RETURN(2)
RETURN(0)
