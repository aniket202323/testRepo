CREATE PROCEDURE dbo.spEM_IEImportBOMFormulationItem
@Formulation_Desc nvarchar(255),
@Alias 	  	  	  	 nvarchar(50),
@ProdCode 	  	  	 nvarchar(255),
@StdQuanity 	  	 nvarchar(255),
@StdQuanityPrec 	  	 nvarchar(255),
@LTolerence 	  	 nvarchar(255),
@LTolerencePrec 	  	 nvarchar(255),
@UTolerence 	  	 nvarchar(255),
@UTolerencePrec 	  	 nvarchar(255),
@Eng_Code  	  	 nvarchar(255),
@ScrapFactor 	 nvarchar(255),
@Lot_Desc 	  	  	 nvarchar(255),
@Mat_Line 	  	  	 nvarchar(255),
@Mat_Unit 	  	  	 nvarchar(255),
@Loc_Line 	  	  	 nvarchar(255),
@Loc_Unit 	  	  	 nvarchar(255),
@Loc_Code 	  	  	 nvarchar(255),
@ItemOrder 	  	 nvarchar(255),
@UseEC 	  	  	  	 nvarchar(255),
@Comment 	  	  	 nvarchar(255),
@User_Id  	  	  	 Int
AS
Declare  @BOM_Form_Item_Id int,
 	  	  	 @fStdQuanity 	  	 Float,
 	  	  	 @fScrapFactor 	  	 Float,
 	  	  	 @iLocationId 	  	 int,
 	  	  	 @BOM_Form_Id 	  	 Int,
 	  	  	 @iPUId 	  	  	  	 Int,
 	  	  	 @iLineId 	  	  	  	 Int,
 	  	  	 @iLocPUId 	  	  	 Int,
 	  	  	 @iLocLineId 	  	  	 Int,
 	  	  	 @iProdId 	  	  	  	 Int,
 	  	  	 @iEngUnitid 	  	  	 Int,
 	  	  	 @Comment_Id 	  	  	 Int,
 	  	  	 @iItemOrder 	  	  	 Int,
 	  	  	 @bUseEc 	  	  	  	  	 Bit,
 	  	  	 @fLTolerence 	  	 Float,
 	  	  	 @fUTolerence 	  	 Float,
 	  	  	 @fStdQuanityPrec 	 Float,
 	  	  	 @fLTolerencePrec 	 Float,
 	  	  	 @fUTolerencePrec 	 Float,
 	  	  	 @Product 	  	 nVarChar(25)
Select @Formulation_Desc = LTrim(RTrim(@Formulation_Desc))
Select @ProdCode = LTrim(RTrim(@ProdCode))
Select @StdQuanity = LTrim(RTrim(@StdQuanity))
Select @Eng_Code = LTrim(RTrim(@Eng_Code))
Select @ScrapFactor = LTrim(RTrim(@ScrapFactor))
Select @LTolerence = LTrim(RTrim(@LTolerence))
Select @UTolerence = LTrim(RTrim(@UTolerence))
Select @Lot_Desc = LTrim(RTrim(@Lot_Desc))
Select @Mat_Line = LTrim(RTrim(@Mat_Line))
Select @Mat_Unit = LTrim(RTrim(@Mat_Unit))
Select @Loc_Line = LTrim(RTrim(@Loc_Line))
Select @Loc_Unit = LTrim(RTrim(@Loc_Unit))
Select @Loc_Code = LTrim(RTrim(@Loc_Code))
Select @ItemOrder = LTrim(RTrim(@ItemOrder))
Select @UseEC = LTrim(RTrim(@UseEC))
Select @Comment = LTrim(RTrim(@Comment))
Select @Alias = LTrim(RTrim(@Alias))
If @Formulation_Desc = '' Select @Formulation_Desc = null
If @ProdCode = ''  	  	  	  	 Select @ProdCode = null
If @StdQuanity = ''  	  	  	 Select @StdQuanity = null
If @LTolerence = ''  	  	  	 Select @LTolerence = null
If @UTolerence = ''  	  	  	 Select @UTolerence = null
If @Eng_Code = ''  	  	  	  	 Select @Eng_Code = null
If @ScrapFactor = '' 	  	  	 Select @ScrapFactor = null
If @Lot_Desc = ''  	  	  	  	 Select @Lot_Desc = null
If @Mat_Line = ''  	  	  	  	 Select @Mat_Line = null
If @Mat_Unit = ''  	  	  	  	 Select @Mat_Unit = null
If @Loc_Line = ''  	  	  	  	 Select @Loc_Line = null
If @Loc_Unit = ''  	  	  	  	 Select @Loc_Unit = null
If @Loc_Code = ''  	  	  	  	 Select @Loc_Code = null
If @ItemOrder = ''  	  	  	  	 Select @ItemOrder = null
If @UseEC = ''  	  	  	  	  	  	 Select @UseEC = null
If @Comment = ''  	  	  	  	  	 Select @Comment = null
If @Alias = ''  	  	  	  	  	 Select @Alias = null
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
/*Check Quanity*/
If @StdQuanity is null
 	 Begin
    	 Select 'Failed - Quanity is missing'
    	 RETURN (-100)
   End
If isnumeric(@StdQuanity) = 0
 	 Begin
    	 Select 'Failed - Quanity is not correct'
    	 RETURN (-100)
   End
Select @fStdQuanity = Convert(float,@StdQuanity)
/*Check Quanity Precision*/
If @StdQuanityPrec is null
 	 Begin
    	 Select 'Failed - Quanity Precision is missing'
    	 RETURN (-100)
   End
If isnumeric(@StdQuanityPrec) = 0
 	 Begin
    	 Select 'Failed - Quanity Precision is not correct'
    	 RETURN (-100)
   End
Select @fStdQuanityPrec = Convert(float,@StdQuanityPrec)
If @LTolerence Is Not null
 	 Begin
 	  	 If isnumeric(@LTolerence) = 0
 	  	  	 Begin
 	  	     	 Select 'Failed - Lower Tolerence is not correct'
 	  	     	 RETURN (-100)
 	  	    End
 	  	 Select @fLTolerence = Convert(float,@LTolerence)
   End
If @UTolerence Is Not null
 	 Begin
 	  	 If isnumeric(@UTolerence) = 0
 	  	  	 Begin
 	  	     	 Select 'Failed - Upper Tolerence is not correct'
 	  	     	 RETURN (-100)
 	  	    End
 	  	 Select @fUTolerence = Convert(float,@UTolerence)
   End
If @UTolerencePrec Is null
 	 Begin
    	 Select 'Failed - Upper Tolerance Precision is missing'
    	 RETURN (-100)
   End
 	 If isnumeric(@UTolerencePrec) = 0
 	  	 Begin
 	     	 Select 'Failed - Upper Tolerence Precision is not correct'
 	     	 RETURN (-100)
 	    End
 	 Select @fUTolerencePrec = Convert(float,@UTolerencePrec)
If @LTolerencePrec Is null
 	 Begin
    	 Select 'Failed - Lower Tolerance Precision is missing'
    	 RETURN (-100)
   End
 	 If isnumeric(@LTolerencePrec) = 0
 	  	 Begin
 	     	 Select 'Failed - Lower Tolerence Precision is not correct'
 	     	 RETURN (-100)
 	    End
 	 Select @fLTolerencePrec = Convert(float,@LTolerencePrec)
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
If  @ScrapFactor is null
 	  	 Begin
 	     	 Select 'Failed - Could not find Scrap Factor'
 	     	 RETURN (-100)
 	   End
If isnumeric(@ScrapFactor) = 0
 	 Begin
    	 Select 'Failed - Scrap Factor is not correct'
    	 RETURN (-100)
   End
 Select @fScrapFactor = Convert(float,@ScrapFactor)
If  @Mat_Line is not null
  Begin
 	 Select @iLineId = PL_Id from Prod_Lines where PL_Desc = @Mat_Line
 	 If @iLineId is null
 	  	 Begin
 	     	 Select 'Failed - Material line not found'
 	     	 RETURN (-100)
 	    End
 	 If @Mat_Unit is null
 	  	 Begin
 	     	 Select 'Failed - Material unit missing'
 	     	 RETURN (-100)
 	    End
 	 Select @iPUId = PU_Id from Prod_Units where PU_Desc = @Mat_Unit and pl_Id = @iLineId
 	 If @iPUId is null
 	  	 Begin
 	     	 Select 'Failed - Material unit not found'
 	     	 RETURN (-100)
 	    End
  End
If  @Loc_Line is not null
  Begin
 	 Select @iLocLineId = PL_Id from Prod_Lines where PL_Desc = @Loc_Line
 	 If @iLocLineId is null
 	  	 Begin
 	     	 Select 'Failed - Material location line not found'
 	     	 RETURN (-100)
 	    End
 	 If @Loc_Unit is null
 	  	 Begin
 	     	 Select 'Failed - Material location unit missing'
 	     	 RETURN (-100)
 	    End
 	 Select @iLocPUId = PU_Id from Prod_Units where PU_Desc = @Loc_Unit and pl_Id = @iLocLineId
 	 If @iLocPUId is null
 	  	 Begin
 	     	 Select 'Failed - Material location unit not found'
 	     	 RETURN (-100)
 	    End
 	 If @Loc_Code is null
 	  	 Begin
 	     	 Select 'Failed - Material location code missing'
 	     	 RETURN (-100)
 	    End
 	 Select @iLocationId = Location_Id from Unit_Locations where Location_Code = @Loc_Code and PU_Id = @iLocPUId
 	 If @iLocationId is null
 	  	 Begin
 	     	 Select 'Failed - Material location code not found'
 	     	 RETURN (-100)
 	    End
 	 
  End
 	 If isnumeric(@ItemOrder) = 0
 	  	 Begin
 	  	  	 Select 'Failed - Order of item not found or incorrect'
 	  	  	 RETURN (-100)
 	  	 End
 	 Select @iItemOrder = Convert(Int,@ItemOrder)
 	 If isnumeric(@UseEC) = 0  and @UseEC is not null
 	   Begin
 	  	 Select 'Failed - Use Event Components is not correct '
 	  	 Return(-100)
 	   End 
 	 
 	 If @UseEC is null
 	  	 select @bUseEc = 1
 	 Else
 	  	 select @bUseEc = Convert(bit,@UseEC)
 	 Select @BOM_Form_Item_Id = BOM_Formulation_Id
 	  	 From Bill_Of_Material_Formulation_Item
 	  	 Where BOM_Formulation_Order = @iItemOrder and BOM_Formulation_Id = @BOM_Form_Id
 	 If @BOM_Form_Item_Id IS Not NULL
 	  	 Begin
 	  	   Select 'Failed - Formulation with this order already exists'
 	  	   RETURN (-100)
 	  	 End
 	 select @Product=Prod_Code from Products where Prod_Id=@iProdId
 	 exec spEM_BOMSaveFormulationItem @User_Id,@Alias,@bUseEc,@fScrapFactor,@fStdQuanity,@fStdQuanityPrec,@fLTolerence,@fUTolerence,@fLTolerencePrec,@fUTolerencePrec,@Comment,@iEngUnitid,@iPUId,@iLocationId,@BOM_Form_Id,@Lot_Desc,@Product,@BOM_Form_Item_Id Output
 	 If @BOM_Form_Item_Id IS NULL
 	  	 Begin
 	  	   Select 'Failed - unable to create formulation item'
 	  	   RETURN (-100)
 	  	 End
 	 IF EXISTS(SELECT 1 FROM Bill_Of_Material_Formulation_Item WHERE BOM_Formulation_Item_Id <> @BOM_Form_Item_Id and BOM_Formulation_Order = @iItemOrder and BOM_Formulation_Id = @BOM_Form_Id )
 	 BEGIN
 	  	 Select 'Warning - unable to set formulation item Order'
 	  	 RETURN (-100)
 	 END
 	 ELSE
 	 BEGIN
 	  	 update Bill_Of_Material_Formulation_Item set BOM_Formulation_Order = @iItemOrder where BOM_Formulation_Item_Id=@BOM_Form_Item_Id  and BOM_Formulation_Order <> @iItemOrder
 	 END
RETURN(0)
