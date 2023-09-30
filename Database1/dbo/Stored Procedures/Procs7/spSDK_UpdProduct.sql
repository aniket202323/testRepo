CREATE PROCEDURE dbo.spSDK_UpdProduct
 	 -- Input Parameters
 	 @TransType 	  	  	  	 INT,
 	 @ProductFamilyDesc 	 nvarchar(50),
 	 @ProductDesc 	  	  	 nvarchar(50),
 	 @ProductCode 	  	  	 nvarchar(50),
 	 @UserId 	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @ProdId 	  	  	  	  	 INT = NULL OUTPUT
AS
-- Return Codes
-- 	  	  1: Prod_Id Not Specified on Update/Delete
-- 	  	  2: Product Family Not Found
-- 	  	  3: Product_Desc Cannot Be Blank
-- 	  	  4: Product_Desc Already Exists
-- 	  	  5: Product_Code Cannot Be Blank
-- 	  	  6: Product_Code Already Exists
-- 	  	 11: Product Create Failed
-- 	 to 	 19: 
-- 	  	 21: Product Update Failed
-- 	 to 	 29: 
-- 	  	 31: Product Delete Failed
-- to 39:
DECLARE 	 @ProdFamilyId 	  	  	 INT,
 	  	  	 @RC 	  	  	  	  	  	 INT,
 	  	  	 @Count 	  	  	  	  	 INT
-- Check to Make Sure Prod_Id was passed on Update Or Delete
IF 	 (@ProdId IS NULL OR @ProdId = 0) AND @TransType IN (2,3)
BEGIN
 	 RETURN(1)
END
-- Check For Valid Product Family
SELECT 	 @ProdFamilyId = NULL
SELECT 	 @ProdFamilyId = Product_Family_Id
 	 FROM 	 Product_Family
 	 WHERE 	 Product_Family_Desc = @ProductFamilyDesc
-- If this is an Add or Update and Product Family 
-- not found error out.
IF @ProdFamilyId IS NULL AND @TransType IN (1,2)
BEGIN
 	 RETURN(2)
END
-- Product_Desc Cannot Be Blank
IF LEN(@ProductDesc) = 0
BEGIN
 	 RETURN(3)
END
-- Check for Valid Product Descriptions
SELECT 	 @Count = COUNT(*)
 	 FROM 	 Products
 	 WHERE 	 Product_Family_Id = @ProdFamilyId AND
 	  	  	 Prod_Desc = @ProductDesc AND
 	  	  	 Prod_Id <> @ProdId
IF @Count > 0 AND @TransType IN (1,2)
BEGIN
 	 RETURN(4)
END
-- Product_Code Cannot Be Blank
IF LEN(@ProductCode) = 0
BEGIN
 	 RETURN(5)
END
-- Check for Valid Product Descriptions
SELECT 	 @Count = COUNT(*)
 	 FROM 	 Products
 	 WHERE 	 Product_Family_Id = @ProdFamilyId AND
 	  	  	 Prod_Code = @ProductCode AND
 	  	  	 Prod_Id <> @ProdId
IF @Count > 0 AND @TransType IN (1,2)
BEGIN
 	 RETURN(6)
END
IF @TransType = 1
BEGIN
 	 EXECUTE 	 @RC = spEM_CreateProd
 	  	  	  	  	  	  	 @ProductDesc,
 	  	  	  	  	  	  	 @ProductCode,
 	  	  	  	  	  	  	 @ProdFamilyId,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 0,--@Serialized
 	  	  	  	  	  	  	 @ProdId OUTPUT
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+10)
 	 END
END ELSE
IF @TransType = 2
BEGIN
 	 EXECUTE 	 @RC = spEM_RenameProdCode
 	  	  	  	  	  	  	 @ProdId,
 	  	  	  	  	  	  	 @ProductCode,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+20)
 	 END
 	 EXECUTE 	 @RC = spEM_RenameProdDesc
 	  	  	  	  	  	  	 @ProdId,
 	  	  	  	  	  	  	 @ProductDesc,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+24)
 	 END
END ELSE
IF @TransType = 3
BEGIN
 	 EXECUTE 	 @RC = spEM_DropProd
 	  	  	  	  	  	  	 @ProdId,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+30)
 	 END
END
RETURN(0)
