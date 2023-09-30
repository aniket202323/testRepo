CREATE PROCEDURE dbo.spEM_IEImportCharacteristicGroups
@Prop_Desc  	  	  	 nVarChar(100),
@Characteristic_Grp_Desc 	 nVarChar(100),
@Char_Desc 	  	  	 nVarChar(100),
@User_Id 	  	  	 int
As
Declare @Characteristic_Grp_Id  	 int,
 	 @Char_Id  	  	 int,
 	 @Prop_Id 	  	 int,
 	 @CGD_Id 	  	  	 int
/* Initialization */
Select 	 @Characteristic_Grp_Id 	 = Null,
 	 @Char_Id  	  	 = Null,
 	 @CGD_Id  	  	 = Null,
 	 @Prop_Id  	  	 = Null
Select @Prop_Desc =  LTrim(RTrim(@Prop_Desc))
Select @Characteristic_Grp_Desc =  LTrim(RTrim(@Characteristic_Grp_Desc))
Select @Char_Desc =  LTrim(RTrim(@Char_Desc))
If  @Prop_Desc = '' or @Prop_Desc IS NULL 
    BEGIN
      Select 'Failed - Product Property missing.'
      Return(-100)
    END
If   @Characteristic_Grp_Desc = '' or @Characteristic_Grp_Desc IS NULL 
    BEGIN
      Select 'Failed - Characteristic Group missing.'
      Return(-100)
    END
If  @Char_Desc = '' or @Char_Desc IS NULL 
    BEGIN
      Select 'Failed - Characteristic missing.'
      Return(-100)
    END
/* Get Prop_Id */
Select @Prop_Id = Prop_Id
From Product_Properties
Where Prop_Desc =@Prop_Desc
If @Prop_Id Is Null
    BEGIN
      Select 'Failed - Product Property not found.'
      Return(-100)
    END
/* Get Char_Id */
Select @Char_Id = Char_Id
From Characteristics
Where Char_Desc = @Char_Desc And Prop_Id = @Prop_Id
If @Char_Id Is Null
    BEGIN
      Select 'Failed - Characteristic not found.'
      Return(-100)
    END
Select @Characteristic_Grp_Id = Characteristic_Grp_Id
From Characteristic_Groups
Where Characteristic_Grp_Desc = @Characteristic_Grp_Desc And Prop_Id = @Prop_Id
If @Characteristic_Grp_Id Is Null
  Begin
 	 Execute spEM_CreateCharGroup  @Characteristic_Grp_Desc,@Prop_Id,@User_Id,@Characteristic_Grp_Id OUTPUT
 	 If @Characteristic_Grp_Id is null
 	  	 Begin
       	  	 Select 'Failed - unable to create Characteristic Group.'
       	  	 Return(-100)
 	  	 End
  End
 Select @CGD_Id = CGD_Id
  From Characteristic_Group_Data
  Where Char_Id = @Char_Id And Characteristic_Grp_Id = @Characteristic_Grp_Id
 If @CGD_Id Is Null
 Begin
 	 execute spEM_CreateCharGroupData  @Characteristic_Grp_Id,@Char_Id,@User_Id,@CGD_Id OUTPUT
 	 If @CGD_Id Is Null
 	  	 Begin
       	  	 Select 'Failed - unable to save Characteristic Group Data.'
       	  	 Return(-100)
 	  	 End
 End
Return(0)
