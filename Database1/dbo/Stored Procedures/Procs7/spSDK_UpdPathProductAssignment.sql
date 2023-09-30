CREATE PROCEDURE dbo.spSDK_UpdPathProductAssignment
 	 -- Input Parameters
 	 @TransType 	  	  	  	 INT,
 	 @DeptDesc 	  	  	  	 nvarchar(50),
 	 @PLDesc 	  	  	  	  	 nvarchar(50),
 	 @PathCode 	  	  	  	 nvarchar(50),
 	 @ProdCode 	  	  	  	 nvarchar(50),
 	 @UserId 	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @PEPPId 	  	  	  	  	 INT = NULL OUTPUT
AS
-- Return Codes
-- 	  	  1: Transaction  Type Update not supported for this Data Type
-- 	  	  2: Path Code Cannot be Blank
-- 	  	  3: Path Cannot Be Found
-- 	  	  4: Product_Code not found
-- 	  	  5: Can Not Find Product Path Association
-- 	  	 11: Product Path Association Create Failed
-- 	 to 	 19: 
-- 	  	 21: Product Path Association Failed
-- to 29:
DECLARE 	 @DeptId 	  	  	 INT,
 	  	  	 @PLId 	  	  	  	 INT,
 	  	  	 @PathId 	  	  	 INT,
 	  	  	 @ProdId 	  	  	 INT,
 	  	  	 @RC 	  	  	  	 INT,
 	  	  	 @Count 	  	  	 INT
IF @TransType = 2
BEGIN
 	 RETURN(1)
END
-- Check For Valid Department
SET 	  	 @DeptId = NULL
SELECT 	 @DeptId = Dept_Id
 	 FROM 	 Departments
 	 WHERE 	 Dept_Desc = @DeptDesc
-- Check For Valid Line
SET 	  	 @PLId = NULL
SELECT 	 @PLId = PL_Id
 	 FROM 	 Prod_Lines
 	 WHERE 	 PL_Desc = @PLDesc
-- Check For Valid Path
SET 	  	 @PLId = NULL
SELECT 	 @PLId = PL_Id
 	 FROM 	 Prod_Lines
 	 WHERE 	 PL_Desc = @PLDesc
-- If this is an Add or Update and Path Code is not Populated return error
IF @PathCode IS NULL AND @TransType IN (1)
BEGIN
 	 RETURN(2)
END
-- Check for Valid Path Code
SET 	  	 @PathId = NULL
SELECT 	 @PathId = Path_Id
 	 FROM 	 PrdExec_Paths
 	 WHERE 	 Path_Code = @PathCode
 	 AND 	 PL_Id = @PLId
IF @PathId IS NULL AND @TransType IN (1)
BEGIN
 	 RETURN(3)
END
-- Check for Valid Product Code
SET 	  	 @ProdId = NULL
SELECT 	 @ProdId = Prod_Id
 	 FROM 	 Products
 	 WHERE 	 Prod_Code = @ProdCode
IF @ProdId IS NULL AND @TransType IN (1)
BEGIN
 	 RETURN(4)
END
IF @TransType = 1
BEGIN
 	 IF @PEPPId IS NOT NULL
 	 BEGIN
 	  	 IF (SELECT 	 COUNT(*)
 	  	  	  	 FROM 	 PrdExec_Path_Products
 	  	  	  	 WHERE 	 Prod_Id = @ProdId
 	  	  	  	 AND 	 Path_Id = @PathId
 	  	  	  	 AND 	 PEPP_Id = @PEPPId) = 0
 	  	 BEGIN
 	  	  	 SET 	 @PEPPId = NULL
 	  	 END ELSE
 	  	 BEGIN
 	  	  	 RETURN(0)
 	  	 END
 	 END
 	 EXECUTE 	 @RC = spEMEPC_PutPathProducts
 	  	  	  	  	  	  	 @PathId,
 	  	  	  	  	  	  	 @ProdId,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 @PEPPId OUTPUT
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+10)
 	 END
END ELSE
IF @TransType = 3
BEGIN
 	 IF @PEPPId IS NULL
 	 BEGIN
 	  	 SELECT 	 @PEPPId = PEPP_Id
 	  	  	 FROM 	 PrdExec_Path_Products
 	  	  	 WHERE 	 Prod_Id = @ProdId
 	  	  	 AND 	 Path_Id = @PathId
 	  	 IF @PEPPId IS NULL
 	  	 BEGIN
 	  	  	 RETURN(5)
 	  	 END
 	 END
 	 EXECUTE 	 @RC = spEMEPC_PutPathProducts
 	  	  	  	  	  	  	 @PathId,
 	  	  	  	  	  	  	 @ProdId,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 @PEPPId OUTPUT
 	 
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+20)
 	 END
END
RETURN(0)
