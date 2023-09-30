CREATE PROCEDURE dbo.spEM_IEImportUnitLocations
@iPL_Desc nvarchar(50),
@iPU_Desc nvarchar(50),
@iLocation_Code nvarchar(50),
@iLocation_Desc nvarchar(50),
@iProd_Code nvarchar(50),
@iMaximum_Items nvarchar(50),
@iMaximum_Dimension_X nvarchar(50),
@iMaximum_Dimension_Y nvarchar(50),
@iMaximum_Dimension_Z nvarchar(50),
@iMaximum_Dimension_A nvarchar(50),
@iMaximum_Alarm_Enabled nvarchar(50),
@iMinimum_Items nvarchar(50),
@iMinimum_Dimension_X nvarchar(50),
@iMinimum_Dimension_Y nvarchar(50),
@iMinimum_Dimension_Z nvarchar(50),
@iMinimum_Dimension_A nvarchar(50),
@iMinimum_Alarm_Enabled nvarchar(50),
@Comment_Text nvarchar(255),
@iUser_Id int 	 
AS
Declare
@Location_Id int,
@PL_Id int,
@PU_Id int,
@Prod_Id int,
@Maximum_Items int,
@Maximum_Dimension_X real,
@Maximum_Dimension_Y real,
@Maximum_Dimension_Z real,
@Maximum_Dimension_A real,
@Maximum_Alarm_Enabled bit,
@Minimum_Items int,
@Minimum_Dimension_X real,
@Minimum_Dimension_Y real,
@Minimum_Dimension_Z real,
@Minimum_Dimension_A real,
@Minimum_Alarm_Enabled bit,
@Comment_Id int
/* Initialization */
Select @Location_Id = NULL,
@PL_Id = NULL,
@PU_Id = NULL,
@Prod_Id = NULL,
@Maximum_Items = NULL,
@Maximum_Dimension_X = NULL,
@Maximum_Dimension_Y = NULL,
@Maximum_Dimension_Z = NULL,
@Maximum_Dimension_A = NULL,
@Maximum_Alarm_Enabled = NULL,
@Minimum_Items = NULL,
@Minimum_Dimension_X = NULL,
@Minimum_Dimension_Y = NULL,
@Minimum_Dimension_Z = NULL,
@Minimum_Dimension_A = NULL,
@Minimum_Alarm_Enabled = NULL,
@Comment_Id = NULL
/* Verify Arguments */
If LTrim(RTrim(@iPL_Desc)) = '' or @iPL_Desc = '' or @iPL_Desc IS NULL
  BEGIN
    Select  'Product Line Not Found'
    Return(-100)
  END
If LTrim(RTrim(@iPU_Desc)) = '' or @iPU_Desc = '' or @iPU_Desc IS NULL 
  BEGIN
    Select  'Product Unit Not Found'
    Return(-100)
  END
If LTrim(RTrim(@iLocation_Code)) = '' or @iLocation_Code = '' or @iLocation_Code IS NULL 
  BEGIN
    Select  'Location Code Not Found'
    Return(-100)
  END
Select @iLocation_Code = LTrim(RTrim(@iLocation_Code))
If LTrim(RTrim(@iLocation_Desc)) = '' or @iLocation_Desc = '' or @iLocation_Desc IS NULL 
 	 Select @iLocation_Desc = Null
Else
 	 Select @iLocation_Desc = LTrim(RTrim(@iLocation_Desc))
If LTrim(RTrim(@iProd_Code)) = '' or @iProd_Code = '' or @iProd_Code IS NULL 
 	 Select @iProd_Code = Null
If LTrim(RTrim(@iMaximum_Items)) = '' or @iMaximum_Items = '' or @iMaximum_Items IS NULL 
 	 Select @iMaximum_Items = Null
If LTrim(RTrim(@iMaximum_Dimension_X)) = '' or @iMaximum_Dimension_X = '' or @iMaximum_Dimension_X IS NULL 
 	 Select @iMaximum_Dimension_X = Null
If LTrim(RTrim(@iMaximum_Dimension_Y)) = '' or @iMaximum_Dimension_Y = '' or @iMaximum_Dimension_Y IS NULL 
 	 Select @iMaximum_Dimension_Y = Null
If LTrim(RTrim(@iMaximum_Dimension_Z)) = '' or @iMaximum_Dimension_Z = '' or @iMaximum_Dimension_Z IS NULL 
 	 Select @iMaximum_Dimension_Z = Null
If LTrim(RTrim(@iMaximum_Dimension_A)) = '' or @iMaximum_Dimension_A = '' or @iMaximum_Dimension_A IS NULL 
 	 Select @iMaximum_Dimension_A = Null
If LTrim(RTrim(@iMaximum_Alarm_Enabled)) = '' or @iMaximum_Alarm_Enabled = '' or @iMaximum_Alarm_Enabled IS NULL 
 	 Select @iMaximum_Alarm_Enabled = Null
If LTrim(RTrim(@Minimum_Items)) = '' or @Minimum_Items = '' or @Minimum_Items IS NULL 
 	 Select @Minimum_Items = Null
If LTrim(RTrim(@Minimum_Dimension_X)) = '' or @Minimum_Dimension_X = '' or @Minimum_Dimension_X IS NULL 
 	 Select @Minimum_Dimension_X = Null
If LTrim(RTrim(@Minimum_Dimension_Y)) = '' or @Minimum_Dimension_Y = '' or @Minimum_Dimension_Y IS NULL 
 	 Select @Minimum_Dimension_Y = Null
If LTrim(RTrim(@Minimum_Dimension_Z)) = '' or @Minimum_Dimension_Z = '' or @Minimum_Dimension_Z IS NULL 
 	 Select @Minimum_Dimension_Z = Null
If LTrim(RTrim(@Minimum_Dimension_A)) = '' or @Minimum_Dimension_A = '' or @Minimum_Dimension_A IS NULL 
 	 Select @Minimum_Dimension_A = Null
If LTrim(RTrim(@Minimum_Alarm_Enabled)) = '' or @Minimum_Alarm_Enabled = '' or @Minimum_Alarm_Enabled IS NULL 
 	 Select @Minimum_Alarm_Enabled = Null
If isnumeric(@iMaximum_Items) = 0  and @iMaximum_Items is not null
  Begin
   	 Select 'Failed - Maximum Items Is Not Correct'
   	 Return(-100)
  End 
If isnumeric(@iMaximum_Dimension_X) = 0  and @iMaximum_Dimension_X is not null
  Begin
   	 Select 'Failed - Maximum DimensionX Is Not Correct' 
   	 Return(-100)
  End 
If isnumeric(@iMaximum_Dimension_Y) = 0  and @iMaximum_Dimension_Y is not null
  Begin
   	 Select 'Failed - Maximum DimensionY Is Not Correct'
   	 Return(-100)
  End 
If isnumeric(@iMaximum_Dimension_Z) = 0  and @iMaximum_Dimension_Z is not null
  Begin
   	 Select 'Failed - Maximum DimensionZ Is Not Correct'
   	 Return(-100)
  End 
If isnumeric(@iMaximum_Dimension_A) = 0  and @iMaximum_Dimension_A is not null
  Begin
   	 Select 'Failed - Maximum DimensionA Is Not Correct'
   	 Return(-100)
  End 
If isnumeric(@Minimum_Items) = 0  and @Minimum_Items is not null
  Begin
   	 Select 'Failed - Minimum Items Is Not Correct'
   	 Return(-100)
  End 
If isnumeric(@Minimum_Dimension_X) = 0  and @Minimum_Dimension_X is not null
  Begin
   	 Select 'Failed - Minimum DimensionX Is Not Correct'
   	 Return(-100)
  End 
If isnumeric(@Minimum_Dimension_Y) = 0  and @Minimum_Dimension_Y is not null
  Begin
   	 Select 'Failed - Minimum DimensionY Is Not Correct'
   	 Return(-100)
  End 
If isnumeric(@Minimum_Dimension_Z) = 0 and @Minimum_Dimension_Z is not null
  Begin
   	 Select 'Failed - Minimum DimensionZ- Reset Value Is Not Correct'
   	 Return(-100)
  End 
If isnumeric(@Minimum_Dimension_A) = 0 and @Minimum_Dimension_A is not null
  Begin
   	 Select 'Failed - Minimum DimensionA Is Not Correct'
   	 Return(-100)
  End 
If @iMaximum_Items is NOT NULL
  Select @Maximum_Items = Convert(Int,@iMaximum_Items)
If @iMaximum_Dimension_X is NOT NULL
  Select @Maximum_Dimension_X = Convert(Real,@iMaximum_Dimension_X)
If @iMaximum_Dimension_Y is NOT NULL
  Select @Maximum_Dimension_Y = Convert(Real,@iMaximum_Dimension_Y)
If @iMaximum_Dimension_Z is NOT NULL
  Select @Maximum_Dimension_Z = Convert(Real,@iMaximum_Dimension_Z)
If @iMaximum_Dimension_A is NOT NULL
  Select @Maximum_Dimension_A = Convert(Real,@iMaximum_Dimension_A)
if @iMaximum_Alarm_Enabled is NOT NULL
  Select @Maximum_Alarm_Enabled = @iMaximum_Alarm_Enabled
else
  Select @Maximum_Alarm_Enabled = 0
If @iMinimum_Items is NOT NULL
  Select @Minimum_Items = Convert(Int,@iMinimum_Items)
If @iMinimum_Dimension_X is NOT NULL
  Select @Minimum_Dimension_X = Convert(Real,@iMinimum_Dimension_X)
If @iMinimum_Dimension_Y is NOT NULL
  Select @Minimum_Dimension_Y = Convert(Real,@iMinimum_Dimension_Y)
If @iMinimum_Dimension_Z is NOT NULL
  Select @Minimum_Dimension_Z = Convert(Real,@iMinimum_Dimension_Z)
If @iMinimum_Dimension_A is NOT NULL
  Select @Minimum_Dimension_A = Convert(Real,@iMinimum_Dimension_A)
if @iMinimum_Alarm_Enabled is NOT NULL
  Select @Minimum_Alarm_Enabled = @iMinimum_Alarm_Enabled
else
  Select @Minimum_Alarm_Enabled = 0
Select @PL_Id = Null
Select @PL_Id = PL_Id from Prod_Lines
 	 Where PL_Desc = @iPL_Desc
If @PL_Id IS NULL
  BEGIN
    Select 'Failed - Invalid Line'
    Return(-100)
  END
Select @PU_Id = Null
Select @PU_Id = PU_Id from Prod_Units 
 	 Where PU_Desc = @iPU_Desc 
 	   and PL_Id = @PL_Id
If @PU_Id IS NULL
  BEGIN
    Select 'Failed - Invalid Unit'
    Return(-100)
  END
If (Select Coalesce(Unit_Type_Id, 0) as Unit_Type_Id From Prod_Units Where PU_Id = @PU_Id) = 0
  BEGIN
    Select 'Failed - Unit Type Not Selected'
    Return(-100)
  END
If (Select ut.Uses_Locations From Unit_Types ut Join Prod_Units pu on pu.Unit_Type_Id = ut.Unit_Type_Id Where pu.PU_Id = @PU_Id) = 0
  BEGIN
    Select 'Failed - Unit Not Configured To Use Locations'
    Return(-100)
  END
Select @Prod_Id = Null
Select @Prod_Id = Prod_Id from Products
 	 Where Prod_Code = @iProd_Code 
-- If (Select Count(*) From Unit_Locations Where PU_Id = @PU_Id and Location_Code = LTrim(RTrim(@iLocation_Code))) > 0
--   BEGIN
--     Select 'Failed - Invalid Location Code'
--     Return(-100)
--   END  
/*******************************************************************************************************************************************
*  	  	  	  	  	 Check For Existing Unit Location 	                                                                                              *
********************************************************************************************************************************************/
Select @Location_Id = Null 
Select @Comment_Id = Null
Select @Location_Id = Location_Id, @Comment_Id = Comment_Id
From Unit_Locations 
Where PU_Id = @PU_Id and Location_Code = @iLocation_Code
If @Location_Id Is Not Null
  Begin
    -- If not imported value then set to table default value
    Select
    @iLocation_Code = IsNull(@iLocation_Code, Location_Code),
    @iLocation_Desc = IsNull(@iLocation_Desc, Location_Desc),
    @Prod_Id = IsNull(@Prod_Id, Prod_Id),
    @Maximum_Items = IsNull(@Maximum_Items, Maximum_Items),
    @Maximum_Dimension_X = IsNull(@Maximum_Dimension_X, Maximum_Dimension_X),
    @Maximum_Dimension_Y = IsNull(@Maximum_Dimension_Y, Maximum_Dimension_Y),
    @Maximum_Dimension_Z = IsNull(@Maximum_Dimension_Z, Maximum_Dimension_Z),
    @Maximum_Dimension_A = IsNull(@Maximum_Dimension_A, Maximum_Dimension_A),
    @Maximum_Alarm_Enabled = IsNull(@Maximum_Alarm_Enabled, Maximum_Alarm_Enabled),
    @Minimum_Items = IsNull(@Minimum_Items, Minimum_Items),
    @Minimum_Dimension_X = IsNull(@Minimum_Dimension_X, Minimum_Dimension_X),
    @Minimum_Dimension_Y = IsNull(@Minimum_Dimension_Y, Minimum_Dimension_Y),
    @Minimum_Dimension_Z = IsNull(@Minimum_Dimension_Z, Minimum_Dimension_Z),
    @Minimum_Dimension_A = IsNull(@Minimum_Dimension_A, Minimum_Dimension_A),
    @Minimum_Alarm_Enabled = IsNull(@Minimum_Alarm_Enabled, Minimum_Alarm_Enabled),
    @Comment_Id = IsNull(@Comment_Id, Comment_Id)
    From Unit_Locations
    Where Location_Id = @Location_Id
  End
  -- Update imported data
  Declare @NewLocationId int
  Select @NewLocationId = NULL
  Execute spEMUP_PutUnitLocations @Location_Id, @PU_Id, @iLocation_Code, @iLocation_Desc, @Prod_Id, 
    @Maximum_Items, @Maximum_Dimension_X, @Maximum_Dimension_Y, @Maximum_Dimension_Z, 
    @Maximum_Dimension_A, @Maximum_Alarm_Enabled, @Minimum_Items, @Minimum_Dimension_X, @Minimum_Dimension_Y, 
    @Minimum_Dimension_Z, @Minimum_Dimension_A, @Minimum_Alarm_Enabled, @iUser_Id, @NewLocationId OUTPUT
 	 If @Comment_Text <> '' and @Comment_Text is not null
 	   Begin
   	  	 If @Comment_Id is null
        Begin
          Insert Into Comments(User_Id, CS_Id, Comment, Comment_Text, Modified_On)
            Values (@iUser_Id, 3, @Comment_Text, @Comment_Text, dbo.fnServer_CmnGetDate(getUTCdate()))
          Select @Comment_Id = Scope_Identity()
          If @Comment_Id IS NULL
            Select 'Warning - Unable to create comment'
          Else
            Update Unit_Locations Set Comment_Id = @Comment_Id Where Location_Id = @NewLocationId
        End
   	  	 Else If @Comment_Id Is not Null
   	  	   Update Comments set comment_text = @Comment_Text, Comment = @Comment_Text Where Comment_Id = @Comment_Id
 	   End 
Return(0)
