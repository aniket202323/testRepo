CREATE PROCEDURE dbo.spEM_IEImportProdExecPathProducts
@PathCode 	  	 nVarChar(100),
@ProdCode 	  	 nVarChar(100),
@UserId 	  	 Int
AS
Declare @PathId 	  	  	 Int,
 	  	 @ProdId  	  	 Int,
 	  	 @PEPPId 	  	  	 Int,
 	  	 @MasterUnit 	  	 Int,
 	  	 @IsActive 	  	 Int
/* Clean and verIFy arguments */
SELECT  	 @PathCode 	  	 = ltrim(rtrim(@PathCode)),
 	  	 @ProdCode  	  	 = ltrim(rtrim(@ProdCode))
IF @PathCode = '' 	  	 SELECT @PathCode = Null
IF @ProdCode = '' 	  	 SELECT @ProdCode = Null
IF @PathCode Is Null 
BEGIN
 	 SELECT 'Failed - Path Code Missing'
 	 Return (-100)
END
IF @ProdCode Is Null 
BEGIN
 	 SELECT 'Failed - Product Code Missing'
 	 Return (-100)
END
SELECT @PathId = Path_Id FROM PrdExec_Paths WHERE Path_Code = @PathCode
IF @PathId Is null
BEGIN
 	 SELECT 'Failed - Unable to Find Path'
 	 Return (-100)
END
SELECT @ProdId = Prod_Id FROM Products WHERE Prod_Code = @ProdCode
IF @ProdId Is null
BEGIN
 	 SELECT 'Failed - Unable to Find product'
 	 Return (-100)
END
SELECT @MasterUnit = PU_Id 
 	 FROM PrdExec_Path_Units 
 	 WHERE Path_Id = @PathId AND Is_Production_Point = 1
IF @MasterUnit Is null
BEGIN
 	 SELECT 'Failed - Unable to Find Production Point'
 	 Return (-100)
END
SELECT @IsActive = Prod_Id
 	 FROM Pu_Products
 	 WHERE PU_Id = @MasterUnit AND  Prod_Id = @ProdId
IF @IsActive Is Null
BEGIN
 	 SELECT 'Failed - Unable to Find Product On Production Point'
 	 Return (-100)
END
SELECT @PEPPId = PEPP_Id
 	 FROM PrdExec_Path_Products
 	 WHERE Path_Id = @PathId And Prod_Id = @ProdId
IF @PEPPId Is Null
BEGIN
 	 EXECUTE spEMEPC_PutPathProducts @PathId,@ProdId,@UserId, @PEPPId OUTPUT
END
IF @PEPPId Is null
BEGIN
 	 SELECT 'Failed - Unable to create Path Product'
 	 Return (-100)
END
