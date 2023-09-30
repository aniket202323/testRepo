CREATE PROCEDURE dbo.spSDK_UpdProductFamily
 	 -- Input Parameters
 	 @TransType 	  	  	  	 INT,
 	 @ProdFamilyDesc 	  	 nvarchar(50),
 	 @UserId 	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @ProdFamilyId 	  	  	 INT OUTPUT
AS
-- Return Codes
-- 	  	  1: Product_Family_Id Not Specified on Update/Delete
-- 	  	  2: Product Family Cannot Be Blank.
-- 	  	  3: Product Family Already Exists
-- 	  	 11: Product Family Create Failed
-- 	 to 	 19: 
-- 	  	 21: Product Family Update Failed
-- 	 to 	 29: 
-- 	  	 31: Product Family Delete Failed
-- to 39:
DECLARE 	 @RC 	  	  	  	  	  	 INT,
 	  	  	 @Count 	  	  	  	  	 INT
-- Check to Make Sure Prod_Id was passed on Update Or Delete
IF 	 (@ProdFamilyId IS NULL) OR (@ProdFamilyId = 0) AND @TransType IN (2,3)
BEGIN
 	 RETURN(1)
END
-- Product_Family_Desc Cannot Be Blank
IF LEN(@ProdFamilyDesc) = 0
BEGIN
 	 RETURN(2)
END
-- Check for Valid Product Descriptions
SELECT 	 @Count = COUNT(*)
 	 FROM 	 Product_Family
 	 WHERE 	 Product_Family_Desc = @ProdFamilyDesc AND
 	  	  	 Product_Family_Id <> @ProdFamilyId
IF @Count > 0 AND @TransType IN (1,2)
BEGIN
 	 RETURN(3)
END
IF @TransType = 1
BEGIN
 	 EXECUTE 	 @RC = spEM_CreateProductFamily
 	  	  	  	  	  	  	 @ProdFamilyDesc,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 @ProdFamilyId OUTPUT
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+10)
 	 END
END ELSE
IF @TransType = 2
BEGIN
 	 EXECUTE 	 @RC = spEM_RenameProductFamily
 	  	  	  	  	  	  	 @ProdFamilyId,
 	  	  	  	  	  	  	 @ProdFamilyDesc,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+20)
 	 END
END ELSE
IF @TransType = 3
BEGIN
 	 EXECUTE 	 @RC = spEM_DropProductFamily
 	  	  	  	  	  	  	 @ProdFamilyId,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+30)
 	 END
END
RETURN(0)
