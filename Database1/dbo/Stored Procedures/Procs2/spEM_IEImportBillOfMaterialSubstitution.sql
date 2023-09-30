CREATE PROCEDURE dbo.spEM_IEImportBillOfMaterialSubstitution
@Formulation_Desc nvarchar(255),
@ItemOrder 	  	  	 nvarchar(255),
@ProdCode 	  	  	 nvarchar(255),
@Eng_Code  	  	  	 nvarchar(255),
@ConversionFactor 	 nvarchar(255),
@SubOrder 	  	  	 nvarchar(255),
@User_Id  	  	  	 Int
AS
Declare  @BOM_Form_Item_Id int,
 	  	  	 @iItemOrder 	  	  	 Int,
 	  	  	 @iProdId 	  	  	  	 Int,
 	  	  	 @iEngUnitid 	  	  	 Int,
 	  	  	 @fConvFact 	  	  	 Float,
 	  	  	 @iSubOrder 	  	  	 Float,
 	  	  	 @BOM_Form_Id 	  	 Int,
 	  	  	 @BOM_Sub_Id 	  	  	 Int
Select @Formulation_Desc = LTrim(RTrim(@Formulation_Desc))
Select @ItemOrder = LTrim(RTrim(@ItemOrder))
Select @ProdCode = LTrim(RTrim(@ProdCode))
Select @Eng_Code = LTrim(RTrim(@Eng_Code))
Select @ConversionFactor = LTrim(RTrim(@ConversionFactor))
Select @SubOrder = LTrim(RTrim(@SubOrder))
If @Formulation_Desc = ''  	 Select @Formulation_Desc = null
If @ItemOrder = ''  	  	  	 Select @ItemOrder = null
If @ProdCode = ''  	  	  	 Select @ProdCode = null
If @Eng_Code = ''  	  	  	 Select @Eng_Code = null
If @ConversionFactor = ''  	 Select @ConversionFactor = null
If @SubOrder = ''  	  	  	 Select @SubOrder = null
/*Check Formulation Desc*/
If @Formulation_Desc IS NULL
    Begin
      Select 'Failed - Formulation description is missing'
      RETURN (-100)
    End
Select @BOM_Form_Id = BOM_Formulation_Id 
      From Bill_Of_Material_Formulation
      Where BOM_Formulation_Desc = @Formulation_Desc
If @BOM_Form_Id IS NULL
    Begin
      Select 'Failed - Could not find formulation'
      RETURN (-100)
    End
If isnumeric(@ItemOrder) = 0
 	 Begin
 	  	 Select 'Failed - Order of item not found or incorrect'
 	  	 RETURN (-100)
 	 End
Select @iItemOrder = Convert(Int,@ItemOrder)
Select @BOM_Form_Item_Id = BOM_Formulation_Item_Id
 	 From Bill_Of_Material_Formulation_Item
 	 Where BOM_Formulation_Order = @iItemOrder and BOM_Formulation_Id = @BOM_Form_Id
If @BOM_Form_Item_Id IS NULL
 	 Begin
 	   Select 'Failed - Formulation [' + Convert(nVarChar(10),@BOM_Form_Id) + '] with this order [' +  Convert(nVarChar(10),@iItemOrder) + '] does not exists'
 	   RETURN (-100)
 	 End
/*Check Product Code*/
If @ProdCode IS NULL
    Begin
      Select 'Failed - Product Code is missing'
      RETURN (-100)
    End
Select @iProdId = Prod_Id 
      From Products
      Where Prod_Code = @ProdCode
If @iProdId IS NULL
    Begin
      Select 'Failed - Could not find Product'
      RETURN (-100)
    End
/*Check Engineering unit*/
If @Eng_Code IS NULL
 	 Begin
 	  	 Select 'Failed - Engineering unit code is missing'
 	  	 RETURN (-100)
 	 End
Select @iEngUnitid = Eng_Unit_Id 
 	 From Engineering_Unit
 	 Where Eng_Unit_Code = @Eng_Code
If @iEngUnitid IS NULL
 	 Begin
 	   Select 'Failed - Could not find engineering unit'
 	   RETURN (-100)
 	 End
If isnumeric(@ConversionFactor) = 0
 	 Begin
    	 Select 'Failed - Conversion Factor is not correct'
    	 RETURN (-100)
   End
 Select @fConvFact = Convert(float,@ConversionFactor)
If isnumeric(@SubOrder) = 0
 	 Begin
 	  	 Select 'Failed - Order of item not found or incorrect'
 	  	 RETURN (-100)
 	 End
Select @iSubOrder = Convert(Int,@SubOrder)
Select @BOM_Sub_Id = BOM_Formulation_Item_Id
  	 From Bill_Of_Material_Substitution
 	 Where BOM_Substitution_Order = @iSubOrder and BOM_Formulation_Item_Id = @BOM_Form_Item_Id
If @BOM_Sub_Id IS Not NULL
 	 Begin
 	   Select 'Failed - Substitution with this order # already exists'
 	   RETURN (-100)
 	 End
 	 Execute spEM_BOMSaveSubstitution   @BOM_Form_Item_Id,@fConvFact,@iEngUnitid,@iSubOrder,@iProdId,@BOM_Sub_Id Output
 	 If @BOM_Sub_Id IS NULL
 	  	 Begin
 	  	   Select 'Failed - unable to create formulation substitution item'
 	  	   RETURN (-100)
 	  	 End
RETURN(0)
