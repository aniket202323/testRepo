CREATE PROCEDURE dbo.spEM_IEImportCalculationInputs
@Result_PL_Desc 	  	 nvarchar(50),
@Result_PU_Desc 	  	 nvarchar(50),
@Result_Var_Desc 	 nvarchar(50),
@Input_PL_Desc 	  	 nvarchar(50),
@Input_PU_Desc 	  	 nvarchar(50),
@Input_Var_Desc 	  	 nvarchar(50),
@Calculation_Name 	 nvarchar(255),
@Alias  	  	  	  	 nvarchar(50),
@Input_Name  	  	 nvarchar(50),
@Entity_Name  	  	 nvarchar(25),
@Attribute_Name  	 nvarchar(25),
@sCalc_Input_Order  	 nVarChar(10),
@Default_Value  	  	 nvarchar(1000),
@Optional_String  	 nVarChar(10),
@Constant_Value 	  	 nvarchar(1000),
@sNonTriggering  	 nVarChar(10),
@User_Id 	  	  	 Int
AS
Declare 	 @Result_PL_Id 	  	  	 int,
 	 @Result_PU_Id 	  	  	  	 int,
 	 @Calc_Input_Order  	  	  	 int,
 	 @Result_Var_Id 	  	  	  	 int,
 	 @Calc_Input_Id  	  	  	  	 int,
 	 @Input_PL_Id 	  	  	  	 int,
 	 @Input_PU_Id 	  	  	  	 int,
 	 @Input_Var_Id  	  	  	  	 int,
 	 @Calculation_Id  	  	  	 int,
 	 @Calc_Input_Entity_Id  	  	 int,
 	 @Calc_Input_Attribute_Id 	 int,
 	 @Optional  	  	  	  	  	 bit,
 	 @NonTriggering 	  	  	  	 bit,
 	 @EntityCheck  	  	  	  	 int,
 	 @AttribCheck  	  	  	  	 int,
 	 @Calc_Input_IdCount  	  	 int,
 	 @Current_Calc_Input_Order 	 int,
 	 @Current_Calc_Input_Entity_Id 	  	 int,
 	 @Current_Calc_Input_Attribute_Id 	 int,
 	 @Current_Optional 	  	  	 bit,
 	 @Current_NonTriggering 	  	 Bit,
 	 @Current_Default_Value 	  	 nvarchar(1000),
 	 @CIEA_Id 	  	  	  	  	 int,
 	 @Result_Var_Count 	  	  	 int,
 	 @Variable_Calculation_Id 	 int,
 	 @Current_Input_Var_Id 	  	 int,
 	 @Current_Result_Var_Id 	  	 int,
 	 @Current_Constant_Value 	  	 nvarchar(1000)
/* Initialization */
Select 	 @Result_PL_Id 	  	  	 = Null,
 	 @Result_PU_Id 	  	  	 = Null,
 	 @Result_Var_Id 	  	  	 = Null,
 	 @Input_PL_Id 	  	  	 = Null,
 	 @Input_PU_Id 	  	  	 = Null,
 	 @Input_Var_Id 	  	  	 = Null,
 	 @Calculation_Id 	  	  	 = Null,
 	 @Calc_Input_Id  	  	 = Null,
 	 @Calc_Input_Entity_Id 	  	 = Null,
 	 @Calc_Input_Attribute_Id 	 = Null,
 	 @Optional 	  	  	 = Null,
 	 @NonTriggering 	  	 = Null,
 	 @CIEA_Id 	  	  	 = Null,
 	 @Current_Input_Var_Id 	  	 = Null,
 	 @Current_Result_Var_Id 	  	 = Null,
 	 @Result_Var_Count 	  	 = 0
/* Clean and verify arguments */
Select 	 @Result_PL_Desc  	 = ltrim(rtrim(@Result_PL_Desc)),
 	 @Result_PU_Desc  	 = ltrim(rtrim(@Result_PU_Desc)),
 	 @Result_Var_Desc  	 = ltrim(rtrim(@Result_Var_Desc)),
 	 @Input_PL_Desc  	 = ltrim(rtrim(@Input_PL_Desc)),
 	 @Input_PU_Desc  	 = ltrim(rtrim(@Input_PU_Desc)),
 	 @Input_Var_Desc  	 = ltrim(rtrim(@Input_Var_Desc)),
 	 @Calculation_Name 	 = ltrim(rtrim(@Calculation_Name)),
 	 @Alias  	  	  	 = ltrim(rtrim(@Alias)),
 	 @Input_Name  	  	 = ltrim(rtrim(@Input_Name)),
 	 @Entity_Name  	  	 = ltrim(rtrim(@Entity_Name)),
 	 @Attribute_Name  	 = ltrim(rtrim(@Attribute_Name)),
 	 @Default_Value  	 = ltrim(rtrim(@Default_Value)),
 	 @Optional_String  	 = ltrim(rtrim(@Optional_String)),
 	 @sNonTriggering  	 = ltrim(rtrim(@sNonTriggering)),
 	 @Constant_Value 	 = ltrim(rtrim(@Constant_Value))
IF isnumeric(@sCalc_Input_Order) = 0
  Begin
 	 Select 'Failed - Missing Calcualation Input Order'
 	 Return (-100)
  End
Else
  Select @Calc_Input_Order = convert(int,@sCalc_Input_Order)
If @Calculation_Name = '' Or @Calculation_Name Is Null
  Begin
 	 Select 'Failed - Missing Calcualation Name'
 	 Return (-100)
  End
If @Result_Var_Desc Is Not NULL
BEGIN
 	 If @Entity_Name <> 'This Event' and @Entity_Name = 'This Variable'
 	 Begin
 	  	 If @Result_PL_Desc = '' Or @Result_PL_Desc Is Null
 	  	 Begin
 	  	  	 Select 'Failed - Missing Production Line'
 	  	  	 Return (-100)
 	  	 End
 	  	 If @Result_PU_Desc = '' Or @Result_PU_Desc Is Null
 	  	   Begin
 	  	  	 Select 'Failed - Missing Production Unit'
 	  	  	 Return (-100)
 	  	   End
 	  	 If @Result_Var_Desc = '' Or @Result_Var_Desc Is Null
 	  	   Begin
 	  	  	 Select 'Failed - Missing Variable'
 	  	  	 Return (-100)
 	  	   End
 	 End
END
If @Default_Value = ''
     Select @Default_Value = Null
If @Constant_Value = ''
     Select @Constant_Value = Null
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Configuration Ids 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
-- Calculation Id 
Select @Calculation_Id = Calculation_Id
From Calculations
Where ltrim(rtrim(Calculation_Name)) = @Calculation_Name
If @Calculation_Id Is Null
  Begin
 	 Select 'Failed - Unable to Find Calculation'
 	 Return (-100)
  End
-- Input Entity
Select @Calc_Input_Entity_Id = Calc_Input_Entity_Id
From Calculation_Input_Entities
Where Entity_Name = @Entity_Name
If @Calc_Input_Entity_Id Is Null 
  Begin
 	 Select 'Failed - Unable to Find Calculation Entity'
 	 Return (-100)
  End
-- Input Attribute
Select @Calc_Input_Attribute_Id = Calc_Input_Attribute_Id
From Calculation_Input_Attributes
Where Attribute_Name = @Attribute_Name
If @Calc_Input_Attribute_Id Is Null 
  Begin
 	 Select 'Failed - Unable to Find Calculation Attribute'
 	 Return (-100)
  End
--Check to see if the Input/Attribute combination is a valid combination
Select @CIEA_Id = CIEA_Id
From Calculation_Input_Entity_Attribute_Data
Where Calc_Input_Entity_Id = @Calc_Input_Entity_Id And Calc_Input_Attribute_Id = @Calc_Input_Attribute_Id
If @CIEA_Id Is Null
  Begin
 	 Select 'Failed - Invalid Entity/Attribute Combination'
 	 Return (-100)
  End
-- Verify constant value
If @Entity_Name <> 'Constant'
     Select @Constant_Value = Null
-- Optional string
If Upper(@Optional_String) = 'TRUE' Or @Optional_String = '1'
     Select @Optional = 1
Else If Upper(@Optional_String) = 'FALSE' Or @Optional_String = '' Or @Optional_String Is Null  Or @Optional_String = '0'
     Select @Optional = 0
Else
  Begin
 	 Select 'Failed - Optional must be true or false'
 	 Return (-100)
  End
-- Optional string
If Upper(@sNonTriggering) = 'TRUE' Or @sNonTriggering = '1'
     Select @NonTriggering = 1
Else If Upper(@sNonTriggering) = 'FALSE' Or @sNonTriggering = '' Or @sNonTriggering Is Null  Or @sNonTriggering = '0'
     Select @NonTriggering = 0
Else
  Begin
 	 Select 'Failed - Non Triggering must be true or false'
 	 Return (-100)
  End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Variable Ids 	   	  	  	  	  	  	  	 *
******************************************************************************************************************************************************/
/* Get PL_Id  */
--If @Entity_Name <> 'This Event' and @Entity_Name <> 'This Variable'
--  Begin
IF @Result_Var_Desc is Not NULL
BEGIN
 	 Select @Result_PL_Id = PL_Id
 	 From Prod_Lines
 	 Where PL_Desc = @Result_PL_Desc
 	 If @Result_PL_Id is Null
 	 Begin
 	  	 Select 'Failed-Production Line not found on the input'
 	  	 Return (-100)
 	 End
 	 /* Get  PU_Id  */
 	 Select @Result_PU_Id = PU_Id
 	 From Prod_Units
 	 Where PU_Desc = @Result_PU_Desc And PL_Id = @Result_PL_Id
 	 If @Result_PU_Id Is Null
 	 Begin
 	  	 Select 'Failed - Production Unit not found'
 	  	 Return (-100)
 	 End
 	 /* Get  Var_Id  */
 	 Select @Result_Var_Id = Var_Id
 	 From Variables
 	 Where Var_Desc = @Result_Var_Desc And PU_Id = @Result_PU_Id
 	 If @Result_Var_Id Is Null
 	 Begin
 	  	 Select 'Failed-Input variable not found'
 	  	 Return (-100)
 	 End
 	 Select @Variable_Calculation_Id = Calculation_Id
 	 From Variables
 	 Where Var_Id = @Result_Var_Id
 	 
 	 If @Calculation_Id <> @Variable_Calculation_Id Or @Variable_Calculation_Id Is Null
 	 Begin
 	  	 Select 'Failed - Calculation not found'
 	  	 Return (-100)
 	 End
END
/******************************************************************************************************************************************************
*  	  	  	  	  	 Verify Calculation Assignment 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
/* Check to see if this calculation is actually assigned to this variable */
If @Entity_Name IN ('Other Variable' ,'Genealogy Variable','Genealogy Variable Alias') and @Input_Var_Desc Is Not Null
  Begin
   Select @Input_PL_Id = PL_Id From Prod_Lines
    Where PL_Desc = @Input_PL_Desc
   If @Input_PL_Id is Null
 	 Begin
 	    Select 'Failed - ' + @Entity_Name + ' Production Line not found'
 	    Return (-100)
 	 End
     /* Get  PU_Id  */
   Select @Input_PU_Id = PU_Id From Prod_Units
     Where PU_Desc = @Input_PU_Desc And PL_Id = @Input_PL_Id
   If @Input_PU_Id Is Null
     Begin
 	    Select 'Failed - ' + @Entity_Name + ' Production Unit not found'
 	    Return (-100)
 	  End
          /* Get  Var_Id  */
   Select @Input_Var_Id = Var_Id From Variables
 	  Where Var_Desc = @Input_Var_Desc And PU_Id = @Input_PU_Id
   If @Input_Var_Id Is Null
 	  Begin
 	    Select 'Failed - ' + @Entity_Name + ' Variable not found'
 	    Return (-100)
 	  End
  End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Create Input     	  	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
--Check to see if the Calculation_Id with that Alias Exists in the Calculation_Inputs Table
Select  	 @Calc_Input_Id  	  	  	 = Calc_Input_Id,
 	 @Current_Calc_Input_Order 	  	 = Calc_Input_Order,
 	 @Current_Calc_Input_Entity_Id 	  	 = Calc_Input_Entity_Id,
 	 @Current_Calc_Input_Attribute_Id 	 = Calc_Input_Attribute_Id,
 	 @Current_Optional 	  	  	 = Optional,
 	 @Current_NonTriggering 	  	  	 = Non_Triggering,
 	 @Current_Default_Value 	  	  	 = Default_Value
From Calculation_Inputs
Where Calculation_Id = @Calculation_Id and Alias = @Alias
/* Check to see if the existing input is the same as the imported input, otherwise do nothing and just Return success */
If @Calc_Input_Id Is Not Null
     Begin
     If @Current_Calc_Input_Order 	 <> @Calc_Input_Order Or
        @Current_Calc_Input_Entity_Id <> @Calc_Input_Entity_Id Or
        @Current_Calc_Input_Attribute_Id <> @Calc_Input_Attribute_Id Or
        @Current_Optional <> @Optional Or @Current_NonTriggering <> @NonTriggering Or
        @Current_Default_Value <> @Default_Value
 	    Begin
 	  	  Select 'Failed - Existing input already exists'
         Return (-100)   	 --Error: Specified input configuration different than existing input configuration
 	    End
     End
/* If non-existent then create new input */
Else
   Begin
     /* If there are other variables referencing the same calculation, then don't allow the addition of more inputs */
     Select @Result_Var_Count = Count(Var_Id)
     From Variables
     Where Calculation_Id = @Calculation_Id And Var_Id <> @Result_Var_Id
     If @Result_Var_Count > 0
 	    Begin
 	  	  Select 'Failed - Specified input configuration different than existing input configuration'
         Return (-100)
 	    End
     /* Create input */
     Insert into Calculation_Inputs (Calculation_Id, Alias, Input_Name, Calc_Input_Entity_Id, Calc_Input_Attribute_Id, Calc_Input_Order, Default_Value, Optional,Non_Triggering)
     Values (@Calculation_Id, @Alias, @Input_Name, @Calc_Input_Entity_Id, @Calc_Input_Attribute_Id, @Calc_Input_Order, @Default_Value, @Optional,@NonTriggering)
     Select @Calc_Input_Id = Scope_Identity()
     If @Calc_Input_Id Is Null
 	    Begin
 	  	  Select 'Failed - Unable to create input'
         Return (-100)
 	    End
   End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Assign Input Variable 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
--Select @Calc_Input_Id,@Input_Var_Id,@Constant_Value
If @Calc_Input_Id Is Not Null And (@Input_Var_Id Is Not Null Or @Constant_Value Is Not Null)
     Begin
     Select @Current_Result_Var_Id  	 = Result_Var_Id, 
  	    @Current_Input_Var_ID  	 = Member_Var_Id,
 	    @Current_Constant_Value 	 = Default_Value
     From Calculation_Input_Data
     Where Calc_Input_Id = @Calc_Input_Id And Result_Var_Id = @Result_Var_Id
     If @Current_Result_Var_Id Is Null
          Begin
          Insert Into Calculation_Input_Data (Calc_Input_Id, Member_Var_Id, Result_Var_Id, Input_Name, Default_Value)
          Values(@Calc_Input_Id, @Input_Var_Id, @Result_Var_Id, @Input_Name, @Constant_Value)
          If @@ROWCOUNT = 0
 	  	  	 Begin
 	  	  	  Select 'Failed - Unable to create input data'
 	  	      Return (-100)   	 
 	  	  	 End
          End
     Else If @Current_Input_Var_Id <> @Input_Var_Id Or @Current_Constant_Value <> @Constant_Value
          Begin
          Update Calculation_Input_Data
          Set  	 Member_Var_Id  	 = @Input_Var_Id,Input_Name  	 = @Input_Name, Default_Value  	 = @Constant_Value
          Where Calc_Input_Id = @Calc_Input_Id And Result_Var_Id = @Result_Var_Id
          If @@ROWCOUNT = 0
 	  	  	 Begin
 	  	  	  Select 'Failed - Unable to create input data'
 	  	      Return (-100)   	 
 	  	  	 End
          End
     End
Return(0)
