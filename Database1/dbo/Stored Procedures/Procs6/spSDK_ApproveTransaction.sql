CREATE Procedure dbo.spSDK_ApproveTransaction
 	 @TransId 	  	  	  	 INT,
 	 @UserId 	  	  	  	 INT,
 	 @GroupName 	  	  	 nvarchar(50),
 	 @EffectiveDate 	  	 DATETIME   OUTPUT
AS
-- Return Status
--
--  0 	  	 = Success
--  1  	 = Transaction Already Approved
-- 10+ 	 = From spEM_ApproveTrans
DECLARE 	 @ApprovedOn   DATETIME,
 	  	  	 @TransCount   INT,
         @GroupId      INT,
 	  	  	 @RC 	  	  	   INT
SELECT 	 @ApprovedOn = Approved_On
 	 FROM 	 Transactions
 	 WHERE 	 Trans_Id = @TransId
IF 	 @ApprovedOn IS NOT NULL RETURN(1)
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
SELECT 	 @TransCount = COUNT(*)
 	 FROM 	 Trans_Variables
 	 WHERE 	 Trans_Id = @TransId
SELECT 	 @TransCount = @TransCount + COUNT(*)
 	 FROM 	 Trans_Products
 	 WHERE 	 Trans_Id = @TransId
SELECT 	 @TransCount = @TransCount + COUNT(*)
 	 FROM 	 Trans_Characteristics
 	 WHERE 	 Trans_Id = @TransId
SELECT 	 @TransCount = @TransCount + COUNT(*)
 	 FROM 	 Trans_Char_Links
 	 WHERE 	 Trans_Id = @TransId
SELECT 	 @TransCount = @TransCount + COUNT(*)
 	 FROM 	 Trans_Properties
 	 WHERE 	 Trans_Id = @TransId
IF @EffectiveDate IS NULL
BEGIN
 	 SELECT 	 @EffectiveDate = dbo.fnServer_CmnGetDate(getUTCdate())
END
IF @TransCount > 0
BEGIN
 	 EXECUTE 	 @RC = spEM_ApproveTrans
 	  	 @TransId, 
 	  	 @UserId, 
 	  	 @GroupId, 
 	  	 NULL,
 	  	 @ApprovedOn 	  	  	 OUTPUT, 
 	  	 @EffectiveDate 	  	 OUTPUT
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC + 10)
 	 END
END 	  	  	  	  	 
RETURN(0)
