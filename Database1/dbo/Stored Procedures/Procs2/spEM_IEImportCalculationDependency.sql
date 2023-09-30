CREATE PROCEDURE dbo.spEM_IEImportCalculationDependency
@Result_PL_Desc 	  	  	 nvarchar(50),
@Result_PU_Desc 	  	  	 nvarchar(50),
@Result_Var_Desc 	  	 nvarchar(50),
@Dependency_PL_Desc 	  	 nvarchar(50),
@Dependency_PU_Desc 	  	 nvarchar(50),
@Dependency_Var_Desc 	 nvarchar(50),
@Calculation_Name 	  	 nvarchar(50),
@Dependency_Name  	  	 nvarchar(50),
@Dependency_Scope_Name  	 nvarchar(25),
@Optional_String  	  	 varchar(5), 	 
@User_Id 	  	  	  	 Int
AS
Declare 	 @Result_PL_Id 	  	  	  	 int,
 	  	 @Result_PU_Id 	  	  	  	 int,
 	  	 @Result_PUG_Id 	  	  	  	 int,
 	  	 @Result_Var_Id 	  	  	  	 int,
 	  	 @Calc_Dependency_Id  	  	 int,
 	  	 @Dependency_PL_Id 	  	  	 int,
 	  	 @Dependency_PU_Id 	  	  	 int,
 	  	 @Dependency_PUG_Id 	  	  	 int,
 	  	 @Dependency_Var_Id 	  	  	 int,
 	  	 @Calculation_Id  	  	  	 int,
 	  	 @Calc_Dependency_Scope_Id  	 int,
 	  	 @Optional  	  	  	  	  	 bit,
 	  	 @Current_Calc_Dependency_Scope_Id 	 int,
 	  	 @Current_Dependency_Var_Id 	 int,
 	  	 @Current_Optional 	  	  	 bit,
 	  	 @Result_Var_Count 	  	  	 int,
 	  	 @Variable_Calculation_Id 	 int
/* Initialization */
Select 	 @Result_PL_Id 	  	  	  	 = Null,
 	 @Result_PU_Id 	  	  	  	 = Null,
 	 @Result_Var_Id 	  	  	  	 = Null,
 	 @Dependency_PL_Id 	  	  	 = Null,
 	 @Dependency_PU_Id 	  	  	 = Null,
 	 @Dependency_Var_Id 	  	  	 = Null,
 	 @Calculation_Id 	  	  	  	 = Null,
 	 @Variable_Calculation_Id 	  	 = Null,
 	 @Calc_Dependency_Id  	  	  	 = Null,
 	 @Calc_Dependency_Scope_Id 	  	 = Null,
 	 @Result_Var_Count 	  	  	 = 0
/* Clean and verify arguments */
Select 	 @Result_PL_Desc  	  	 = ltrim(rtrim(@Result_PL_Desc)),
 	 @Result_PU_Desc  	  	 = ltrim(rtrim(@Result_PU_Desc)),
 	 @Result_Var_Desc  	  	 = ltrim(rtrim(@Result_Var_Desc)),
 	 @Dependency_PL_Desc  	 = ltrim(rtrim(@Dependency_PL_Desc)),
 	 @Dependency_PU_Desc  	 = ltrim(rtrim(@Dependency_PU_Desc)),
 	 @Dependency_Var_Desc  	 = ltrim(rtrim(@Dependency_Var_Desc)),
 	 @Dependency_Name  	  	 = ltrim(rtrim(@Dependency_Name)),
 	 @Dependency_Scope_Name  	 = ltrim(rtrim(@Dependency_Scope_Name)),
 	 @Optional_String  	  	 = ltrim(rtrim(@Optional_String)),
 	 @Calculation_Name 	  	 = ltrim(rtrim(@Calculation_Name))
If @Result_Var_Desc Is Not Null
BEGIN
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
END
If @Dependency_Var_Desc Is Not Null
BEGIN
 	 If @Dependency_PL_Desc = '' Or @Dependency_PL_Desc Is Null
 	   Begin
 	  	 Select 'Failed - Missing Production Line'
 	  	 Return (-100)
 	   End
 	 If @Dependency_PU_Desc = '' Or @Dependency_PU_Desc Is Null
 	   Begin
 	  	 Select 'Failed - Missing Production Unit'
 	  	 Return (-100)
 	   End
END
If @Calculation_Name = '' Or @Calculation_Name Is Null
  Begin
 	 Select 'Failed - Missing Calculation Name'
 	 Return (-100)
  End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Configuration Ids 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
-- Calculation Id
Select @Calculation_Id = Calculation_Id
From Calculations
Where ltrim(rtrim(Calculation_Name)) = @Calculation_Name
If @Calculation_Id Is Null
  Begin
 	 Select 'Failed - Missing Calculation'
 	 Return (-100)
  End
-- Dependency Id
Select @Calc_Dependency_Scope_Id = Calc_Dependency_Scope_Id
From Calculation_Dependency_Scopes
Where Calc_Dependency_Scope_Name = @Dependency_Scope_Name
If @Calc_Dependency_Scope_Id Is Null 
  Begin
 	 Select 'Failed - Missing Scope Name'
 	 Return (-100)
  End
-- Optional 
If Upper(@Optional_String) = 'TRUE' or @Optional_String = '1'
     Select @Optional = 1
Else If Upper(@Optional_String) = 'FALSE' Or @Optional_String = '' Or @Optional_String Is Null Or @Optional_String = '0'
     Select @Optional = 0
Else
  Begin
 	 Select 'Failed - Optional must be true or false'
 	 Return (-100)
  End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Variable Ids 	   	  	  	  	  	  	  	 *
******************************************************************************************************************************************************/
/* Get PL_Id  */
If @Result_Var_Desc Is Not Null
BEGIN
 	 Select @Result_PL_Id = PL_Id
 	   From Prod_Lines
 	  Where PL_Desc = @Result_PL_Desc
 	 
 	 If @Result_PL_Id Is Null
 	   Begin
 	  	 Select 'Failed - Invalid Production Line'
 	  	 Return (-100)
 	   End
 	 Select @Result_PU_Id = PU_Id
 	  From Prod_Units
 	  Where PU_Desc = @Result_PU_Desc And PL_Id = @Result_PL_Id
 	 
 	 If @Result_PU_Id Is Null
 	   Begin
 	  	 Select 'Failed - Invalid Production Unit'
 	  	 Return (-100)
 	   End
 	 
 	 Select @Result_Var_Id = Var_Id
 	    From Variables
 	    Where Var_Desc = @Result_Var_Desc And PU_Id = @Result_PU_Id
 	 If @Result_Var_Id Is Null
 	   Begin
 	  	 Select 'Failed - Invalid Variable'
 	  	 Return (-100)
 	   End
END
If @Dependency_Var_Desc Is Not Null
BEGIN
 	 Select @Dependency_PL_Id = PL_Id
 	   From Prod_Lines
 	  Where PL_Desc = @Dependency_PL_Desc
 	 
 	 If @Dependency_PL_Id Is Null
 	   Begin
 	  	 Select 'Failed - Invalid Production Line'
 	  	 Return (-100)
 	   End
 	 Select @Dependency_PU_Id = PU_Id
 	  From Prod_Units
 	  Where PU_Desc = @Dependency_PU_Desc And PL_Id = @Dependency_PL_Id
 	 
 	 If @Dependency_PU_Id Is Null
 	   Begin
 	  	 Select 'Failed - Invalid Production Unit'
 	  	 Return (-100)
 	   End
 	 
 	 Select @Dependency_Var_Id = Var_Id
 	    From Variables
 	    Where Var_Desc = @Dependency_Var_Desc And PU_Id = @Dependency_PU_Id
 	 If @Dependency_Var_Id Is Null
 	   Begin
 	  	 Select 'Failed - Invalid Variable'
 	  	 Return (-100)
 	   End
END
/******************************************************************************************************************************************************
*  	  	  	  	  	 Verify Calculation Assignment 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
/* Check to see if this calculation is actually assigned to this variable */
If @Result_Var_Id Is Not Null
BEGIN
 	 Select @Variable_Calculation_Id = Calculation_Id
 	 From Variables
 	 Where Var_Id = @Result_Var_Id
 	 
 	 If @Calculation_Id <> @Variable_Calculation_Id Or @Variable_Calculation_Id Is Null
 	   Begin
 	  	 Select 'Failed - Variable does not match calculation'
 	  	 Return (-100)
 	   End
END
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Create Dependency 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
--Check to see if the Calculation_Id with that Alias Exists in the Calculation_Inputs Table
Select  	 @Calc_Dependency_Id  	  	  	 = Calc_Dependency_Id,
 	 @Current_Calc_Dependency_Scope_Id 	 = Calc_Dependency_Scope_Id,
 	 @Current_Optional 	  	  	 = Optional
From Calculation_Dependencies
Where Calculation_Id = @Calculation_Id And Name = @Dependency_Name
/* Check to see if the existing dependency is the same as the imported input, otherwise do nothing and just Return success */
If @Calc_Dependency_Id Is Not Null
     Begin
     If @Current_Calc_Dependency_Scope_Id <> @Calc_Dependency_Scope_Id Or @Current_Optional <> @Optional
 	   Begin
 	  	 Select 'Failed - Specified dependency configuration different than existing dependency configuration'
 	  	 Return (-100)
 	   End
     End
/* If non-existent then create new dependency */
Else
     Begin 
     /* If there are other variables referencing the same calculation, then don't allow the addition of more inputs */
     IF @Result_Var_Id Is Not NULL
     BEGIN
 	      Select @Result_Var_Count = Count(Var_Id)
 	      From Variables
 	      Where Calculation_Id = @Calculation_Id And Var_Id <> @Result_Var_Id
 	 
 	      If @Result_Var_Count > 0
 	   	   Begin
 	  	  	 Select 'Failed - Imported definition does not match existing calculation configuration'
 	  	  	 Return (-100)
 	  	   End
     END
     Insert into Calculation_Dependencies (Calculation_Id, Name, Calc_Dependency_Scope_Id, Optional)
     Values (@Calculation_Id, @Dependency_Name, @Calc_Dependency_Scope_Id, @Optional)
     Select @Calc_Dependency_Id = Scope_Identity()
     If @Calc_Dependency_Id Is Null
   	   Begin
 	  	 Select 'Failed - Failure to create row in Calculation_Inputs'
 	  	 Return (-100)
 	   End
     End
/******************************************************************************************************************************************************
*  	  	  	  	  	 Assign Dependent Variable 	  	  	  	  	  	  	 *
******************************************************************************************************************************************************/ 
If @Dependency_Var_Id Is Not Null And @Calc_Dependency_Id Is Not Null
     Begin
     /* Check for existing assignments */
     Select @Current_Dependency_Var_Id = Var_Id
     From Calculation_Dependency_Data
     Where Calc_Dependency_Id = @Calc_Dependency_Id And Result_Var_Id = @Result_Var_Id
     If @Current_Dependency_Var_Id Is Null
          Begin
          Insert into Calculation_Dependency_Data (Calc_Dependency_Id, Result_Var_Id, Var_Id)
           	 Values (@Calc_Dependency_Id, @Result_Var_Id, @Dependency_Var_Id)
          If @@ROWCOUNT = 0
 	  	    	   Begin
 	  	  	  	 Select 'Failed - Failure to create row in Calculation_Inputs'
 	  	  	  	 Return (-100)
 	  	  	   End
          End
     Else If @Current_Dependency_Var_Id <> @Dependency_Var_Id
          Begin
          Update Calculation_Dependency_Data
          Set Var_Id = @Dependency_Var_Id
          Where Calc_Dependency_Id = @Calc_Dependency_Id And Result_Var_Id = @Result_Var_Id
          If @@ROWCOUNT = 0
 	  	    	   Begin
 	  	  	  	 Select 'Failed - Failure to create row in Calculation_Inputs'
 	  	  	  	 Return (-100)
 	  	  	   End
          End
     End
Return(0)
