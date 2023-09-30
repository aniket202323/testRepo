CREATE procedure [dbo].[spSDK_AU_BOMSubstitution_Bak_177]
@AppUserId int,
@Id bigint OUTPUT,
@BOMFormulationItemId bigint ,
@BOMSubstitutionOrder int ,
@ConversionFactor float ,
@EngineeringUnit varchar(100) ,
@EngineeringUnitId int ,
@ProductCode varchar(100) ,
@ProductId int 
AS
DECLARE @EngCode 	  	  	 VarChar(50),
 	  	  	  	 @ProdCode 	  	  	 VarChar(25),
 	  	  	  	 @BOMFormDesc 	 VarChar(255),
 	  	  	  	 @ItemOrder 	  	 Int
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
SELECT @ProdCode = Prod_Code
 	 FROM Products
 	 WHERE Prod_Id = @ProductId 
IF @Id Is NULL
BEGIN
 	 SELECT @BOMFormDesc =  b.BOM_Formulation_Desc ,@ItemOrder = a.BOM_Formulation_Order  
 	  	  	 FROM Bill_Of_Material_Formulation_Item  a
 	  	  	 JOIN Bill_Of_Material_Formulation b ON b.BOM_Formulation_Id = a.BOM_Formulation_Id 
 	  	  	 WHERE  a.BOM_Formulation_Item_Id = @BOMFormulationItemId
 	 SELECT @EngCode = Eng_Unit_Code 
 	  	 FROM Engineering_Unit
 	  	 WHERE Eng_Unit_Desc = @EngineeringUnit
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportBillOfMaterialSubstitution @BOMFormDesc,@ItemOrder,@ProdCode,@EngCode,@ConversionFactor,@BOMSubstitutionOrder,@AppUserId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 SELECT @Id = a.BOM_Substitution_Id
 	  	  	 FROM Bill_Of_Material_Substitution a
 	  	  	 WHERE a.BOM_Formulation_Item_Id   = @BOMFormulationItemId and a.Prod_Id  = @ProductId
END
ELSE
BEGIN
 	 EXECUTE spEM_BOMSaveSubstitution   @BOMFormulationItemId,@ConversionFactor,@EngineeringUnitId,@BOMSubstitutionOrder,@ProductId,@Id Output
END
RETURN(1)
