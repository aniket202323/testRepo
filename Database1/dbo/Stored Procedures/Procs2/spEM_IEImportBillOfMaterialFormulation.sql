CREATE PROCEDURE dbo.spEM_IEImportBillOfMaterialFormulation
@BOM_Desc nvarchar(255),
@Formulation_Desc nvarchar(255),
@Master_Formulation_Desc nvarchar(255),
@EffectiveDate nvarchar(255),
@ExpirationDate nvarchar(255),
@StdQuanity nvarchar(255),
@StdQuanityPrec nvarchar(255),
@Eng_Code  	  	  	 nvarchar(255),
@Comment 	  	  	 nvarchar(255),
@User_Id int
AS
Declare  @Master_BOM_Formulation_Id int,
 	  	  	 @BOM_Id int,
 	  	  	 @fStdQuanity Float,
 	  	  	 @fStdQuanityPrec Float,
 	  	  	 @dExpirationDate DateTime,
 	  	  	 @dEffectiveDate 	 DateTime,
 	  	  	 @BOM_Form_Id Int,
 	  	  	 @Comment_Id 	  	  	 Int,
 	  	  	 @iEngUnitid 	  	  	 Int
Select @Master_Formulation_Desc = LTrim(RTrim(@Master_Formulation_Desc))
Select @Formulation_Desc = LTrim(RTrim(@Formulation_Desc))
Select @EffectiveDate = LTrim(RTrim(@EffectiveDate))
Select @ExpirationDate = LTrim(RTrim(@ExpirationDate))
Select @StdQuanity = LTrim(RTrim(@StdQuanity))
Select @BOM_Desc = LTrim(RTrim(@BOM_Desc))
Select @Eng_Code = LTrim(RTrim(@Eng_Code))
Select @Comment = LTrim(RTrim(@Comment))
If @EffectiveDate = '' Select @EffectiveDate = null
If @ExpirationDate = '' Select @ExpirationDate = null
If @Eng_Code = '' Select @Eng_Code = null
Select @BOM_Id = Null
Select @BOM_Id = BOM_Id from Bill_Of_Material 
 	 where BOM_Desc = @BOM_Desc
If @BOM_Id IS NULL
    BEGIN
      Select 'Failed - Bill Of Material Not Found'
      RETURN (-100)
    END
If @Formulation_Desc IS NULL or @Formulation_Desc = ''
    BEGIN
      Select 'Failed - Formulation Description missing'
      RETURN (-100)
    END
if @StdQuanityPrec is null or @StdQuanityPrec=''
    BEGIN
      Select 'Failed - Formulation Quantity Precision missing'
      RETURN (-100)
    END
Select @BOM_Form_Id = NULL
Select @BOM_Form_Id = BOM_Formulation_Id 
      From Bill_Of_Material_Formulation
      Where BOM_Formulation_Desc = @Formulation_Desc
If @BOM_Form_Id IS Not NULL
    BEGIN
      Select 'Failed - Formulation name already exists'
      RETURN (-100)
    END
If @Master_Formulation_Desc <> '' and @Master_Formulation_Desc IS NOT NULL
  BEGIN
    Select @Master_BOM_Formulation_Id = NULL
    Select @Master_BOM_Formulation_Id = BOM_Formulation_Id 
      From Bill_Of_Material_Formulation
      Where BOM_Formulation_Desc = @Master_Formulation_Desc
    If @Master_BOM_Formulation_Id IS NULL
 	  	 Begin
       	 Select 'Failed - Could not find Master Formulation'
       	 RETURN (-100)
      End
   End
 	 If @StdQuanity = '' or @StdQuanity is null
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
 	 Select @fStdQuanityPrec = Convert(float,@StdQuanityPrec)
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
 	 If @EffectiveDate is not null
 	 BEGIN
 	  	 If Len(@EffectiveDate)  <> 14 
 	  	 BEGIN
 	  	  	 Select  'Failed - Could not convert effective date to datetime'
 	  	  	 Return(-100)
 	  	 END
 	  	 SELECT @dEffectiveDate = 0
 	  	 SELECT @dEffectiveDate = DateAdd(year,convert(int,substring(@EffectiveDate,1,4)) - 1900,@dEffectiveDate)
 	  	 SELECT @dEffectiveDate = DateAdd(month,convert(int,substring(@EffectiveDate,5,2)) - 1,@dEffectiveDate)
 	  	 SELECT @dEffectiveDate = DateAdd(day,convert(int,substring(@EffectiveDate,7,2)) - 1,@dEffectiveDate)
 	  	 SELECT @dEffectiveDate = DateAdd(hour,convert(int,substring(@EffectiveDate,9,2)) ,@dEffectiveDate)
 	  	 SELECT @dEffectiveDate = DateAdd(minute,convert(int,substring(@EffectiveDate,11,2)),@dEffectiveDate)
 	  	 IF @dEffectiveDate < '1/1/1971' 
 	  	 BEGIN
 	       Select 'Failed - Effective date is to far in the past'
 	       RETURN (-100)
 	  	 END
 	 END
 	 else
 	     BEGIN
 	       Select 'Failed - Effective date is missing'
 	       RETURN (-100)
 	     END
 	 If @ExpirationDate is not null
 	 BEGIN
 	  	 If Len(@ExpirationDate)  <> 14 
 	  	 BEGIN
 	  	  	 Select  'Failed - Could not convert expiration date to datetime'
 	  	  	 Return(-100)
 	  	 END
 	  	 SELECT @dExpirationDate = 0
 	  	 SELECT @dExpirationDate = DateAdd(year,convert(int,substring(@ExpirationDate,1,4)) - 1900,@dExpirationDate)
 	  	 SELECT @dExpirationDate = DateAdd(month,convert(int,substring(@ExpirationDate,5,2)) - 1,@dExpirationDate)
 	  	 SELECT @dExpirationDate = DateAdd(day,convert(int,substring(@ExpirationDate,7,2)) - 1,@dExpirationDate)
 	  	 SELECT @dExpirationDate = DateAdd(hour,convert(int,substring(@ExpirationDate,9,2)) ,@dExpirationDate)
 	  	 SELECT @dExpirationDate = DateAdd(minute,convert(int,substring(@ExpirationDate,11,2)),@dExpirationDate)
 	  	 IF @dExpirationDate < '1/1/1971' 
 	  	 BEGIN
 	       Select 'Failed - Expiration date is to far in the past'
 	       RETURN (-100)
 	  	 END
 	  	 IF @dExpirationDate < @dEffectiveDate
 	  	 BEGIN
 	       Select 'Failed - Expiration date must be after Effective date'
 	       RETURN (-100)
 	  	 END
 	 END
 	 exec spEM_BOMSaveFormulation  @BOM_Id,@DeffectiveDate,@dExpirationDate,@fStdQuanity,@StdQuanityPrec, @iEngUnitid,@Comment ,@Master_BOM_Formulation_Id ,@User_Id,@Formulation_Desc,@BOM_Form_Id OUTPUT
   If @BOM_Form_Id IS NULL
    BEGIN
      Select 'Failed - Could not create Bill Of Material Formulation'
      RETURN (-100)
    END
RETURN(0)
