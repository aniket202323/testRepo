CREATE procedure [dbo].[spSDK_AU_BOMFormulationItem]
@AppUserId int,
@Id int OUTPUT,
@Alias varchar(50) ,
@BOMFormulation varchar(100) ,
@BOMFormulationId bigint ,
@BOMFormulationOrder int ,
@CommentId int OUTPUT,
@CommentText text ,
@Department varchar(100) ,
@DepartmentId int ,
@EngineeringUnit varchar(100) ,
@EngineeringUnitId int ,
@Lot varchar(50) ,
@LowerTolerance float ,
@LowerTolerancePrecision int ,
@ProductCode varchar(50) ,
@ProductId int ,
@ProductionLine varchar(100) ,
@ProductionLineId int ,
@ProductionUnit varchar(100) ,
@ProductionUnitId int ,
@Quantity float ,
@QuantityPrecision int ,
@ScrapFactor float ,
@UnitLocation varchar(100) ,
@UnitLocationId int ,
@UpperTolerance float ,
@UpperTolerancePrecision int ,
@UseEventComponents bit 
AS
DECLARE @EngCode 	  	  	 VarChar(50),
 	  	  	  	 @ProdCode 	  	  	 VarChar(25),
 	  	  	  	 @sComment 	  	  	 VarChar(255),
 	  	  	  	 @ULLocation 	  	 VarChar(50),
 	  	  	  	 @PLLocation 	  	 VarChar(50),
 	  	  	  	 @LocCode 	  	  	 VarChar(50)
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId OUTPUT
/*
For TOM ... Location Id = LocationCode and Prod Unit
*/
SELECT @ProdCode = Prod_Code
 	 FROM Products
 	  	 WHERE Prod_Id = @ProductId 
IF @Id IS NULL
BEGIN
 	 SELECT @EngCode = Eng_Unit_Code 
 	  	 FROM Engineering_Unit
 	  	 WHERE Eng_Unit_Desc = @EngineeringUnit
 	 SELECT @sComment = SUBSTRING(@CommentText,1,255)
 	 SELECT @ULLocation = b.PU_Desc,@PLLocation = c.PL_Desc,@LocCode = a.Location_Code 
 	  	 FROM Unit_Locations a 
 	  	 JOIN Prod_Units_Base b ON b.PU_Id = a.PU_Id
 	  	 JOIN Prod_Lines_Base c ON c.PL_Id = b.PL_Id 
 	  	 WHERE Location_Id = @UnitLocationId
 	  	 
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportBillOfMaterialFormulationItem @BOMFormulation,@Alias,@ProdCode,@Quantity,@QuantityPrecision,
 	  	  	  	  	  	 @LowerTolerance,@LowerTolerancePrecision,@UpperTolerance,@UpperTolerancePrecision,@EngCode,
 	  	  	  	  	  	 @ScrapFactor,@Lot,@ProductionLine,@ProductionUnit,@PLLocation,
 	  	  	  	  	  	 @ULLocation,@LocCode,@BOMFormulationOrder,@UseEventComponents,@sComment,@AppUserId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 SELECT @Id =  BOM_Formulation_Item_Id,@CommentId = Comment_id  
 	  	  	 FROM Bill_Of_Material_Formulation_Item  a
 	  	  	 WHERE a.BOM_Formulation_Order  = @BOMFormulationOrder and a.BOM_Formulation_Id = @BOMFormulationId
 	 IF @CommentId IS Not NULL
 	 BEGIN
 	  	 UPDATE Comments SET Comment = @CommentText, Comment_Text = @CommentText WHERE Comment_Id = @CommentId
 	 END
END
ELSE
BEGIN
 	 EXECUTE spEM_BOMSaveFormulationItem @AppUserId,@Alias,@UseEventComponents,@ScrapFactor,@Quantity,
 	  	  	  	  	  	 @QuantityPrecision,@LowerTolerance,@UpperTolerance,@LowerTolerancePrecision,@UpperTolerancePrecision,
 	  	  	  	  	  	 @CommentText,@EngineeringUnitId,@ProductionUnitId,@UnitLocationId,@BOMFormulationId,
 	  	  	  	  	  	 @Lot,@ProdCode,@Id Output
 	  	  	  	  	 
 	 Select @CommentId = Comment_Id From Bill_Of_Material_Formulation_Item Where BOM_Formulation_Item_Id = @Id
 	 If (@CommentId Is Not NULL)
 	  	 Update Comments Set Comment_Text = @CommentText Where Comment_Id = @CommentId 	 
 	  	  	  	  	  	 
END
Return(1)
