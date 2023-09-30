CREATE PROCEDURE dbo.spEM_IEImportAdditionalDependency
@Result_PL_Desc 	  	  	 nvarchar(50),
@Result_PU_Desc 	  	  	 nvarchar(50),
@Result_Var_Desc 	  	 nvarchar(50),
@Dependency_PL_Desc 	  	 nvarchar(50),
@Dependency_PU_Desc 	  	 nvarchar(50),
@Dependency_Var_Desc 	 nvarchar(50),
@Calculation_Name 	  	 nvarchar(50),
@Dependency_Scope_Name  	 nvarchar(25),
@User_Id 	  	  	  	 Int
AS
Declare 	 @Result_PL_Id 	  	  	  	 int,
 	  	 @Result_PU_Id 	  	  	  	 int,
 	  	 @Result_PUG_Id 	  	  	  	 int,
 	  	 @Result_Var_Id 	  	  	  	 int,
 	  	 @Dependency_Var_Id  	  	  	 int,
 	  	 @Dependency_PL_Id 	  	  	 int, 
 	  	 @Dependency_PU_Id  	  	  	 int, 
 	  	 @Dependency_PUG_Id  	  	  	 int,
 	  	 @Calc_Dependency_Scope_Id  	 int,
 	  	 @Calculation_Id 	  	  	  	 int,
 	  	 @Variable_Calculation_Id 	 int,
 	  	 @Current_Dependency_Var_Id 	 int,
 	  	 @Current_Dependency_Scope_Id 	 int
/* Initialize */
Select  	 @Result_PL_Id 	  	  	  	 = Null,
 	 @Result_PU_Id 	  	  	  	 = Null,
 	 @Result_Var_Id 	  	  	  	 = Null,
 	 @Dependency_PL_Id  	  	  	 = Null,
 	 @Dependency_PU_Id 	  	  	 = Null,
 	 @Dependency_Var_Id 	  	  	 = Null,
 	 @Calculation_Id 	  	  	  	 = Null,
 	 @Calc_Dependency_Scope_Id 	  	 = Null,
 	 @Current_Dependency_Var_Id 	  	 = Null,
 	 @Current_Dependency_Scope_Id 	 = Null
/* Clean and verify arguments */
Select 	 @Result_PL_Desc 	  	  	 = ltrim(rtrim(@Result_PL_Desc)),
 	 @Result_PU_Desc 	  	  	 = ltrim(rtrim(@Result_PU_Desc)),
 	 @Result_Var_Desc 	  	  	 = ltrim(rtrim(@Result_Var_Desc)),
 	 @Dependency_PL_Desc  	  	 = ltrim(rtrim(@Dependency_PL_Desc)),
 	 @Dependency_PU_Desc  	  	 = ltrim(rtrim(@Dependency_PU_Desc)),
 	 @Dependency_Var_Desc  	  	 = ltrim(rtrim(@Dependency_Var_Desc)),
 	 @Calculation_Name 	  	  	 = ltrim(rtrim(@Calculation_Name))
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
If @Dependency_Var_Desc = '' Or @Dependency_Var_Desc Is Null
  Begin
 	 Select 'Failed - Missing Variable'
 	 Return (-100)
  End
If @Calculation_Name = '' Or @Calculation_Name Is Null
  Begin
 	 Select 'Failed - Missing Calculation Name'
 	 Return (-100)
  End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Configuration Ids 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
Select @Calculation_Id = Calculation_Id
From Calculations
Where ltrim(rtrim(Calculation_Name)) = @Calculation_Name
If @Calculation_Id Is Null
  Begin
 	 Select 'Failed - Unable to find Calculation Name'
 	 Return (-100)
  End
Select @Calc_Dependency_Scope_Id = Calc_Dependency_Scope_Id
From Calculation_Dependency_Scopes
Where Calc_Dependency_Scope_Name = @Dependency_Scope_Name
If @Calc_Dependency_Scope_Id Is Null 
  Begin
 	 Select 'Failed - Unable to find Calculation scope'
 	 Return (-100)
  End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Variable Ids 	   	  	  	  	  	  	  	 *
******************************************************************************************************************************************************/
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
/******************************************************************************************************************************************************
*  	  	  	  	  	 Verify Calculation Assignment 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
Select @Variable_Calculation_Id = Calculation_Id
From Variables
Where Var_Id = @Result_Var_Id
If @Calculation_Id <> @Variable_Calculation_Id Or @Variable_Calculation_Id Is Null
  Begin
 	 Select 'Failed - Variable does not match calculation'
 	 Return (-100)
  End
/******************************************************************************************************************************************************
*  	  	  	  	  	 Assign Dependent Variable 	  	  	  	  	  	  	 *
******************************************************************************************************************************************************/
Select  	 @Current_Dependency_Var_Id  	  	 = Var_Id,
 	 @Current_Dependency_Scope_Id 	 = Calc_Dependency_Scope_Id
From Calculation_Instance_Dependencies
Where Result_Var_Id = @Result_Var_Id And Var_Id = @Dependency_Var_Id
If @Current_Dependency_Var_Id Is Null
     Begin
     Insert into Calculation_Instance_Dependencies (Result_Var_Id, Var_Id, Calc_Dependency_Scope_Id)
     Values(@Result_Var_Id, @Dependency_Var_Id, @Calc_Dependency_Scope_Id)
     If @@ROWCOUNT = 0
  	   Begin
 	  	 Select 'Failed - failed to insert additional dependency'
 	  	 Return (-100)
 	   End
     End
Else If @Current_Dependency_Scope_Id <> @Calc_Dependency_Scope_Id
     Begin
 	      Update Calculation_Instance_Dependencies
 	      Set Calc_Dependency_Scope_Id = @Calc_Dependency_Scope_Id
 	      Where Result_Var_Id = @Result_Var_Id And Var_Id = @Dependency_Var_Id
 	 
 	      If @@ROWCOUNT = 0
 	   	   Begin
 	  	  	 Select 'Failed - failed to insert additional dependency'
 	  	  	 Return (-100)
 	  	   End
     End
Return(0)
