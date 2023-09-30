CREATE PROCEDURE dbo.spEM_IEImportBillOfMaterialProduct
@ProdCode nvarchar(255),
@BOM_Desc nvarchar(255),
@PL_Desc nvarchar(50),
@PU_Desc nvarchar(50),
@User_Id int
AS
Declare 
  @BOM_Form_Id 	 Int,
  @Prod_Id 	  	  	 Int,
  @BOMProdId 	  	 Int,
  @PUId 	  	  	  	  	 Int,
  @PLId 	  	  	  	  	 Int
SET @BOM_Desc = LTrim(RTrim(@BOM_Desc))
SET @ProdCode = LTrim(RTrim(@ProdCode))
SET @PL_Desc = LTrim(RTrim(@PL_Desc))
SET @PU_Desc = LTrim(RTrim(@PU_Desc))
IF @PU_Desc = '' 	 SET @PU_Desc = NULL
IF @PL_Desc = '' 	 SET @PL_Desc = NULL
If @BOM_Desc = '' SET @BOM_Desc = Null
If @ProdCode = '' SET @ProdCode = Null
IF @PU_Desc IS NOT NULL
BEGIN
 	 If @PL_Desc IS NULL
 	 BEGIN
 	  	 Select 'Failed - Production Line Missing'
 	  	 Return(-100)
 	 END
 	 SELECT @PLId = PL_Id 
 	  	 FROM Prod_Lines
 	  	 WHERE PL_Desc = @PL_Desc
 	 If @PLId Is Null
 	 BEGIN
 	  	 SELECT 'Failed - Production Line not Found'
 	  	 RETURN(-100)
 	 END
 	 SELECT @PUId = PU_Id 
 	  	 FROM Prod_Units 
 	  	 WHERE PU_Desc = @PU_Desc And PL_Id = @PLId
 	 If @PUId IS NULL
 	 BEGIN
 	  	 SELECT 'Failed - Production Unit not Found'
 	  	 RETURN(-100)
 	 END
END
If @ProdCode IS NULL
BEGIN
 	 SELECT 'Failed - Product Code Missing'
 	 RETURN (-100)
END
SELECT @Prod_Id = Prod_Id FROM Products 
 	 WHERE Prod_Code = @ProdCode
If @Prod_Id IS NULL
BEGIN
 	 SELECT 'Failed - Product Code Not Found'
 	 RETURN (-100)
END
If @BOM_Desc IS NULL
BEGIN
  SELECT 'Failed - Formulation Description Missing'
  RETURN (-100)
END
SELECT @BOM_Form_Id = BOM_Formulation_Id 
 	 FROM Bill_Of_Material_Formulation
 	 WHERE BOM_Formulation_Desc = @BOM_Desc
If @BOM_Form_Id IS NULL
BEGIN
  SELECT 'Failed - Formulation Description Not Found'
  RETURN (-100)
END
SELECT @BOMProdId = BOM_Product_Id
 	 FROM Bill_Of_Material_Product
 	 WHERE BOM_Formulation_Id = @BOM_Form_Id and Prod_Id = @Prod_Id and (@PUId=PU_Id or (@PUId is null and PU_Id is null))
If @BOMProdId IS Not NULL
    BEGIN
      SELECT 'Failed - Formulation / Product / Unit already exists'
      RETURN (-100)
    END
if @PUId is not null
 	 if not exists(SELECT * FROM PU_Products WHERE Prod_Id=@Prod_Id and PU_Id=@PUId)
 	     BEGIN
 	       SELECT 'Failed - Unit not available for this product'
 	       RETURN (-100)
 	     END
exec spEM_BOMSaveFormulationProduct @BOM_Form_Id,@Prod_Id,@PUId
RETURN(0)
