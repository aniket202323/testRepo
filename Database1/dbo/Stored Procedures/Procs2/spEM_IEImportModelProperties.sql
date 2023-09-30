CREATE PROCEDURE dbo.spEM_IEImportModelProperties
 	 @ModelDesc 	 nVarChar(100),
 	 @Optional  	 nVarChar(100),
 	 @Locked  	  	 nVarChar(100),
 	 @FieldDesc  	 nvarchar(255),
 	 @FieldType 	 nVarChar(100),
 	 @DefaultValue 	 nvarchar(255),
 	 @UserId  	  	 Int
AS
Declare  	 @ModelId 	  	  	 Int,
 	  	 @iFieldType 	  	 Int,
 	  	 @OptionalBit 	  	 Bit,
 	  	 @LockedBit 	  	 Bit,
 	  	 @iFieldPropId 	  	 Int
 	  	 
/* Clean arguments */
Select  	 @ModelDesc  	 = nullif(RTrim(LTrim(@ModelDesc)),''),
 	  	 @Optional 	  	 = nullif(RTrim(Ltrim(@Optional)),''),
 	  	 @Locked 	  	 = nullif(RTrim(Ltrim(@Locked)),''),
 	  	 @FieldDesc 	 = nullif(RTrim(Ltrim(@FieldDesc)),''),
 	  	 @FieldType 	 = nullif(RTrim(Ltrim(@FieldType)),''),
 	  	 @DefaultValue 	 = nullif(RTrim(Ltrim(@DefaultValue)),'')
/* Take care of nonNullable fields  sp_Help ED_fields*/
     If @ModelDesc Is Null
 	    Begin
 	  	 Select 'Failed - Model Description Missing'
 	  	 Return(-100)
 	    End
 	 Select @ModelId = ed_Model_Id from ed_Models where Model_Desc = @ModelDesc
     If @ModelId Is Null
 	    Begin
 	  	 Select 'Failed - Model Description not Found'
 	  	 Return(-100)
 	    End
     If @Optional Is Null
 	    Begin
 	  	 Select 'Failed - Optional Missing'
 	  	 Return(-100)
 	    End
     If @Locked Is Null
 	    Begin
 	  	 Select 'Failed - Is Locked Missing'
 	  	 Return(-100)
 	    End
     If @FieldDesc Is Null
 	    Begin
 	  	 Select 'Failed - Field Description Missing'
 	  	 Return(-100)
 	    End
     If @FieldType Is Null
 	    Begin
 	  	 Select 'Failed - Field Type Missing'
 	  	 Return(-100)
 	    End
 	 Select @iFieldPropId = ED_Field_Prop_Id
 	  	 From ed_field_properties
 	  	 Where ED_Model_Id = @ModelId and Field_Desc = @FieldDesc
 	 If @iFieldPropId Is Not Null
 	    Begin
 	  	 Select 'Failed - Property already exists'
 	  	 Return(-100)
 	    End
 	 Select @iFieldType = ED_Field_Type_Id
 	  	 From ed_Fieldtypes
 	  	 Where Field_Type_Desc = @FieldType
 	 If @iFieldType Is Null
 	    Begin
 	  	 Select 'Failed - Field Type Not correct'
 	  	 Return(-100)
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
Insert Into ed_field_properties(Optional, Locked, ED_Model_Id, ED_Field_Type_Id, Default_Value, Field_Desc)
VALUES(@OptionalBit, @LockedBit, @ModelId, @iFieldType, @DefaultValue, @FieldDesc)
