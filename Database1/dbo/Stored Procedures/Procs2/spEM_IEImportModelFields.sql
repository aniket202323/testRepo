CREATE PROCEDURE dbo.spEM_IEImportModelFields
 	 @ModelDesc 	 nVarChar(100),
 	 @FieldOrder  	 nVarChar(100),
 	 @FieldDesc 	 nVarChar(100),
 	 @DefaultValue  	 nvarchar(255),
 	 @Optional  	 nVarChar(100),
 	 @Locked  	  	 nVarChar(100),
 	 @UsePercision  	 nVarChar(100),
 	 @Percision  	 nVarChar(100),
 	 @CommentText 	 nvarchar(255),
 	 @UserId  	  	 Int
AS
Declare  	 @ModelId 	  	  	 Int,
 	  	 @iFieldId 	  	  	 Int,
 	  	 @ifieldOrder 	  	 Int,
 	  	 @DerivedModelId 	 Int,
 	  	 @DerivedModelNum 	 Int,
 	  	 @DerivedFieldId 	 int,
 	  	 @iFieldType 	  	 Int,
 	  	 @iPercision  	  	 Int,
 	  	 @OptionalBit 	  	 Bit,
 	  	 @LockedBit 	  	 Bit,
 	  	 @UsePercisionBit 	 Bit,
 	  	 @ModelFieldDesc 	 nVarChar(100),
 	  	 @CommentId 	  	 Int,
 	  	 @DerivedOptional 	 Int
 	  	 
/* Clean arguments */
Select  	 @ModelDesc  	 = nullif(RTrim(LTrim(@ModelDesc)),''),
 	   	 @FieldOrder  	 = nullif(RTrim(LTrim(@FieldOrder)),''),
 	  	 @FieldDesc 	 = nullif(RTrim(Ltrim(@FieldDesc)),''),
 	  	 @DefaultValue 	 = nullif(RTrim(Ltrim(@DefaultValue)),''),
 	  	 @Optional 	  	 = nullif(RTrim(Ltrim(@Optional)),''),
 	  	 @Locked 	  	 = nullif(RTrim(Ltrim(@Locked)),''),
 	  	 @UsePercision 	 = nullif(RTrim(Ltrim(@UsePercision)),''),
 	  	 @Percision 	 = nullif(RTrim(Ltrim(@Percision)),''),
 	  	 @CommentText 	  	 = nullif(RTrim(Ltrim(@CommentText)),'')
/* Take care of nonNullable fields  sp_Help ED_fields*/
     If @ModelDesc Is Null
 	    Begin
 	  	 Select 'Failed - Model Description Not Found'
 	  	 Return(-100)
 	    End
     If @FieldOrder Is Null
 	    Begin
 	  	 Select 'Failed - Field Order Not Found'
 	  	 Return(-100)
 	    End
     If @FieldDesc Is Null
 	    Begin
 	  	 Select 'Failed - Field Description Not Found'
 	  	 Return(-100)
 	    End
     If @Locked Is Null
 	    Begin
 	  	 Select 'Failed - Is Locked Not Found'
 	  	 Return(-100)
 	    End
     If @Optional Is Null
 	    Begin
 	  	 Select 'Failed - Optional Not Found'
 	  	 Return(-100)
 	    End
 	 If isnumeric(@FieldOrder) = 0
 	   Begin
 	  	 Select 'Failed - Field order not correct '
 	  	 Return(-100)
 	   End 
 	 Select @iFieldOrder = Convert(int,@FieldOrder)
/* Check to see if already exists */
 	 Select @ModelId = ed_Model_Id,@DerivedModelNum = Derived_From from ed_Models where Model_Desc = @ModelDesc
     If @ModelId Is Null
 	    Begin
 	  	 Select 'Failed - Model Description not Found'
 	  	 Return(-100)
 	    End
 	 Select @DerivedModelId = ed_Model_Id From ed_Models where Model_Num = @DerivedModelNum
     If @DerivedModelId Is Null
 	    Begin
 	  	 Select 'Failed - Main Model derived model number not Found'
 	  	 Return(-100)
 	    End
 	 Select @iFieldId = ED_Field_Id from ed_fields where ED_Model_Id = @ModelId and Field_Order = @iFieldOrder
     If @iFieldId Is Not Null
 	    Begin
 	  	 Select 'Failed - Field already exists'
 	  	 Return(-100)
 	    End
 	 Select @DerivedFieldId = ed_field_Id,@iFieldType = ED_Field_Type_Id, @ModelFieldDesc = Field_Desc,@DerivedOptional = Optional
 	  	 From ed_fields 
 	  	 Where ED_Model_Id = @DerivedModelId and Field_Order = @iFieldOrder
    If @DerivedFieldId Is Null
 	    Begin
 	  	 Select 'Failed - Derived field not found'
 	  	 Return(-100)
 	    End
 	 If (RTrim(LTrim(@ModelFieldDesc)) <> RTrim(LTrim(@FieldDesc))) and @DerivedOptional = 0
 	 Begin
 	  	 SELECT @FieldDesc =  RTrim(LTrim(@ModelFieldDesc))
 	 End
 	 If isnumeric(@Optional) = 0 or (@Optional <> '1' and @Optional <> '0')
 	   Begin
 	  	 Select 'Failed - Optional not correct '
 	  	 Return(-100)
 	   End 
 	 Select @OptionalBit = Convert(bit,@Optional)
 	 If isnumeric(@Locked) = 0 or (@Locked <> '1' and @Locked <> '0')
 	   Begin
 	  	 Select 'Failed - Locked not correct '
 	  	 Return(-100)
 	   End 
 	 Select @LockedBit = Convert(bit,@Locked)
 	 If @UsePercision is not null
 	   Begin
 	  	 If isnumeric(@UsePercision) = 0 or (@UsePercision <> '1' and @UsePercision <> '0')
 	  	   Begin
 	  	  	 Select 'Failed - Use percision not correct '
 	  	  	 Return(-100)
 	  	   End 
 	  	 Select @UsePercisionBit = Convert(bit,@UsePercision)
 	   End
 	 If @Percision is not null
 	   Begin
 	  	 If isnumeric(@Percision) = 0  
 	  	   Begin
 	  	  	 Select 'Failed - percision not correct '
 	  	  	 Return(-100)
 	  	   End 
 	  	 Select @iPercision = Convert(Int,@Percision)
 	   End
 	 Select @CommentId = Null
 	 If @CommentText is not null 
 	   Begin
     	  	 Insert into Comments (Comment, User_Id, Modified_On, CS_Id) 
 	  	  	 Select @CommentText,@UserId,dbo.fnServer_CmnGetDate(getUTCdate()),1
 	  	 Select @CommentId = SCOPE_IDENTITY()
 	  	 If @CommentId IS NULL
 	  	  	 Select 'Warning - Unable to create comment'
 	   End
Insert Into ED_Fields(Field_Order, Max_instances, Comment_Id, ED_Model_Id, Derived_From,
 	  	  	  	   ED_Field_Type_Id, Default_Value, Optional, Locked, Field_Desc, Percision, Use_Percision)
VALUES(@FieldOrder, 1,@CommentId,@ModelId,@DerivedFieldId,@iFieldType, @DefaultValue,
 	 @OptionalBit,@LockedBit,@FieldDesc,@iPercision,@UsePercisionBit)
