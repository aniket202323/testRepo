CREATE procedure [dbo].[spSDK_AU_BOMProduct]
@AppUserId int,
@Id int OUTPUT,
@BOMFormulation varchar(100) ,
@BOMFormulationId bigint ,
@Department varchar(200) ,
@DepartmentId int ,
@ProductCode varchar(100) ,
@ProductId int ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int 
AS
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId OUTPUT
DECLARE 	 @ProdCode 	  	  	 VarChar(25)
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
SELECT @ProdCode = Prod_Code
 	 FROM Products
 	 WHERE Prod_Id = @ProductId 
IF @Id IS NULL
BEGIN
 	 INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportBillOfMaterialProduct 	 @ProdCode,@BOMFormulation,@ProductionLine,@ProductionUnit,@AppUserId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 IF @ProductionUnit IS NULL
 	 BEGIN
 	  	 SELECT @Id = a.BOM_Product_Id 
 	  	  	 FROM Bill_Of_Material_Product a
 	  	  	 WHERE a.PU_Id Is NULL AND a.Prod_Id = @ProductId AND a.BOM_Formulation_Id = @BOMFormulationId
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @Id = a.BOM_Product_Id 
 	  	  	 FROM Bill_Of_Material_Product a
 	  	  	 WHERE a.PU_Id = @ProductionUnitId AND a.Prod_Id = @ProductId AND a.BOM_Formulation_Id = @BOMFormulationId
 	 END
END
ELSE
BEGIN
 	 UPDATE Bill_Of_Material_Product SET Prod_Id = @ProductId,BOM_Formulation_Id = @BOMFormulationId,PU_Id = @ProductionUnitId 
 	  	 WHERE BOM_Product_Id = @Id
END
Return(1)
