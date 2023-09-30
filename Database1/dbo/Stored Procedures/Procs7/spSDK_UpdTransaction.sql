CREATE Procedure dbo.spSDK_UpdTransaction
 	 @UserId 	  	  	  	 INT,
 	 @TransId 	  	  	  	 INT,
 	 @GroupName 	  	  	 nvarchar(50),
 	 @TransName 	  	  	 nvarchar(50)
AS
-- Return Status
--
--  0 	  	 = Success
--  1+ 	 = Error Renaming Transaction
-- 10+ 	 = Error Changing Groups
DECLARE 	 @RC 	  	  	    	 INT,
 	  	  	 @CurrentName 	 nvarchar(50),
 	  	  	 @GroupId 	  	  	 INT,
 	  	  	 @CurrentGroup 	 INT
SELECT 	 @CurrentGroup = NULL,
 	  	  	 @CurrentName = NULL
SELECT 	 @CurrentGroup = Transaction_Grp_Id,
 	  	  	 @CurrentName = Trans_Desc
 	 FROM 	 Transactions
 	 WHERE 	 Trans_Id = @TransId
SELECT 	 @GroupId = NULL
SELECT 	 @GroupId = Transaction_Grp_Id
 	 FROM 	 Transaction_Groups
 	 WHERE 	 Transaction_Grp_Desc = @GroupName
IF @GroupId IS NULL AND @GroupName <> ''
BEGIN
 	 EXECUTE 	 spEM_CreateApprovedGroup
 	  	  	  	   @GroupName,
 	  	  	  	   @UserId,
 	  	  	  	   @GroupId 	 OUTPUT
END
IF @GroupId IS NULL
BEGIN
 	 SELECT 	 @GroupId = 1
END
IF @TransName <> @CurrentName
BEGIN
 	 EXECUTE 	 @RC = spEM_RenameTrans
 	  	 @TransId, 
 	  	 @TransName,
 	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC)
 	 END
END 	  	  	  	  	 
IF @CurrentGroup <> @GroupId
BEGIN
 	 EXECUTE 	 @RC = spEM_ChangeApprovedGroup
 	  	 @TransId, 
 	  	 @GroupId, 
 	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC + 10)
 	 END
END 	  	  	  	  	 
RETURN(0)
