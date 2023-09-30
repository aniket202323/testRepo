CREATE PROCEDURE dbo.spEM_IEImportProdXRef
 	 @ProdCode 	  	 nVarChar(100),
 	 @ProdXRefCode 	 nvarchar(255),
 	 @PLDesc 	  	  	 nVarChar(100),
 	 @PUDesc 	  	  	 nVarChar(100),
 	 @UserId 	  	  	 Int
AS
Declare @IsMaster  	 Int,
 	 @PLId 	  	  	 Int,
 	 @PUId 	  	  	 Int,
 	 @ProdId 	  	  	 Int,
 	 @DefaultXFef 	 nvarchar(255)
/* Clean Arguments */
Select @ProdXRefCode = LTrim(RTrim(@ProdXRefCode))
Select @PLDesc = RTrim(LTrim(@PLDesc))
Select @PUDesc = RTrim(LTrim(@PUDesc))
Select @ProdCode = RTrim(LTrim(@ProdCode))
If @ProdXRefCode = '' 	 Select @ProdXRefCode = Null
If @PLDesc = '' 	  	  	 Select @PLDesc = Null
If @PUDesc = '' 	  	  	 Select @PUDesc = Null
If @ProdCode = '' 	  	 Select @ProdCode = Null
If @ProdCode is null
BEGIN
 	 Select 'Failed - Can not find product Code'
 	 Return (-100)
END
SELECT @ProdId = Prod_Id FROM Products where Prod_Code = @ProdCode
If @ProdId is null
BEGIN
 	 Select 'Failed - Can not find product code'
 	 Return (-100)
END
If @ProdXRefCode is null
BEGIN
 	 Select 'Failed - Can not find product cross reference'
 	 Return (-100)
END
If @PLDesc IS Not NULL
BEGIN
 	 Select @PLId = PL_Id From Prod_Lines Where PL_Desc = @PLDesc
 	 If @PLId IS NULL
 	 BEGIN
 	  	 Select 'Failed - Production Line not found'
 	  	 Return(-100)
 	 END
END
SELECT @DefaultXFef = Prod_Code_XRef FROM  Prod_XRef Where PU_Id Is Null and Prod_Id = @ProdId
If @PUDesc IS Not NULL 
BEGIN
 	 If @PLId IS NULL
 	 BEGIN
 	  	 Select 'Failed - Production Line not found'
 	  	 Return(-100)
 	 END
 	 Select @PUId = PU_Id,@IsMaster = Master_Unit from Prod_Units  Where PU_Desc = @PUDesc and PL_Id = @PLId
 	 IF @PUId Is Null
    BEGIN
      Select  'Production Unit Not Found On Line'
      Return(-100)
    END
 	 IF @IsMaster Is Not Null
    BEGIN
      Select  'Production Unit must be a Master Unit'
      Return(-100)
    END
 	 /* Check if this is the default */
 	 IF @ProdXRefCode = @DefaultXFef 
 	  	 SELECT @ProdXRefCode = NULL
END
ELSE
BEGIN
 	 If @PLId IS NOT NULL
 	 BEGIN
 	  	 Select 'Failed - Production Unit not found'
 	  	 Return(-100)
 	 END
END
EXECUTE spEM_PutProductXRef @ProdId,@PUId,@ProdXRefCode,@UserId
