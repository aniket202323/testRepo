CREATE PROCEDURE dbo.spEM_IEImportCalculation
 	 @PL_Desc 	  	 nvarchar(50),
 	 @PU_Desc 	  	 nvarchar(50),
 	 @Var_Desc 	  	 nvarchar(50),
 	 @Calculation_Name  	 nvarchar(255),
 	 @Calculation_Desc  	 nvarchar(255),
 	 @Calculation_Type  	 nvarchar(25),
 	 @Equation  	  	 nvarchar(255),
 	 @Trigger_Type  	  	 nvarchar(50),
 	 @sLag_Time  	  	 nVarChar(10),
 	 @sMax_Run_Time  	  	 nVarChar(10),
 	 @Version  	  	 nVarChar(10),
 	 @sLocked  	  	 nVarChar(10),
 	 @SP_Name  	  	 nvarchar(50),
 	 @Script  	  	 varchar(8000),
 	 @Comment_Text  	  	 nvarchar(1000),
 	 @OptimizeRun 	  	 nVarChar(10),
 	 @User_Id 	  	 Int
AS
Declare 	 @Result_PL_Id 	  	 int,
 	 @Result_PU_Id 	  	  	 int,
 	 @Current_Var_Id 	  	  	 int,
 	 @Calculation_Type_Id  	 int,
 	 @Trigger_Type_Id 	  	 int,
 	 @Comment_Id 	  	  	  	 int,
 	 @Variable_Calculation_Id 	 int,
 	 @Current_Calculation_Type_Id int,
 	 @Current_Trigger_Type_Id 	 int,
 	 @Current_Equation 	 nvarchar(255),
 	 @Current_Script 	  	 varchar(8000),
 	 @Current_SP_Name 	 nvarchar(50),
 	 @Result_Var_Id 	  	 int, 	 
 	 @Calculation_Id 	   	 int,
 	 @Lag_Time  	  	  	 int,
 	 @Max_Run_Time  	  	 int,
 	 @Locked  	  	  	 int,
 	 @iOptimizeRun 	  	 Int
/* Initialization */
Select 	 @Result_PL_Id 	 = Null,
 	 @Result_PU_Id 	  	 = Null,
 	 @Result_Var_Id 	  	 = Null,
 	 @Comment_Id  	  	 = Null,
 	 @Calculation_Id 	  	 = Null,
 	 @Calculation_Type_Id= Null,
 	 @Trigger_Type_Id 	 = Null,
 	 @Variable_Calculation_Id= Null
/* Clean and validate arguments */
Select 	 @PL_Desc  	  	 = LTrim(RTrim(@PL_Desc)),
 	 @PU_Desc  	  	 = LTrim(RTrim(@PU_Desc)),
 	 @Var_Desc  	  	 = LTrim(RTrim(@Var_Desc)),
 	 @Calculation_Name 	 = LTrim(RTrim(@Calculation_Name)),
 	 @Calculation_Desc 	 = LTrim(RTrim(@Calculation_Desc)),
 	 @Calculation_Type 	 = LTrim(RTrim(@Calculation_Type)),
 	 @Equation 	  	 = LTrim(RTrim(@Equation)),
 	 @Trigger_Type 	  	 = LTrim(RTrim(@Trigger_Type)),
 	 @Version 	  	 = LTrim(RTrim(@Version)),
 	 @SP_Name 	  	 = LTrim(RTrim(@SP_Name)),
 	 @Script 	  	  	 = LTrim(RTrim(@Script)),
 	 @Comment_Text  	  	 = LTrim(RTrim(@Comment_Text)),
 	 @OptimizeRun 	  	 = LTrim(RTrim(@OptimizeRun))
/*
If @PL_Desc = '' Or @PL_Desc Is Null
  Begin
 	 Select 'Failed - Missing Production Line'
 	 Return (-100)
  End
If @PU_Desc = '' Or @PU_Desc Is Null
  Begin
 	 Select 'Failed - Missing Production Unit'
 	 Return (-100)
  End
If @Var_Desc = '' Or @Var_Desc Is Null
  Begin
 	 Select 'Failed - Missing Variable'
 	 Return (-100)
  End
*/
If @Calculation_Name = '' Or @Calculation_Name Is Null
  Begin
 	 Select 'Failed - Missing Calculation Name'
 	 Return (-100)
  End
If @Calculation_Desc = '' Or @Calculation_Desc Is Null
  Begin
 	 Select 'Failed - Missing Calculation Description'
 	 Return (-100)
  End
If @Calculation_Type = '' or @Calculation_Type Is Null
   Begin
 	 Select 'Failed - Missing Calculation Type'
 	 Return (-100)
  End
If @Trigger_Type = '' or @Trigger_Type Is Null
  Begin
 	 Select 'Failed - Missing Trigger Type'
 	 Return (-100)
  End
If @Version = '' or @Version Is Null
     Select @Version = '1.0'
If @sLocked = '' or @sLocked Is Null or @sLocked = '0'
     Select @Locked = 0
Else
 	 Select @Locked = 1
If @OptimizeRun = '' or @OptimizeRun Is Null or @OptimizeRun = '1' or Upper(@OptimizeRun) = 'TRUE'
 	 Select @iOptimizeRun = 1
Else
 	 Select @iOptimizeRun = 0
If @sLag_Time = '' or @sLag_Time Is Null or isnumeric(@sLag_Time) = 0
     Select @Lag_Time = 0
Else
 	 Select @Lag_Time = Convert(Int,@sLag_Time)
If @sMax_Run_Time = '' or @sMax_Run_Time Is Null or isnumeric(@sMax_Run_Time) = 0
     Select @Max_Run_Time = 0
Else
 	 Select @Max_Run_Time = Convert(Int,@sMax_Run_Time)
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Configuration Ids 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
Select @Calculation_Type_Id = Calculation_Type_Id 
From Calculation_Types
Where Calculation_Type_Desc = @Calculation_Type
If @Calculation_Type_Id Is Null
   Begin
 	 Select 'Failed - Invalid Calculation Type'
 	 Return (-100)
  End
Select @Trigger_Type_Id = Trigger_Type_Id 
From Calculation_Trigger_Types
Where Name = @Trigger_Type
If @Trigger_Type_Id Is Null
   Begin
 	 Select 'Failed - Invalid Trigger Type'
 	 Return (-100)
  End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Variable Ids 	   	  	  	  	  	  	  	 *
******************************************************************************************************************************************************/
/* Get PL_Id  */
IF @Var_Desc Is Not Null
BEGIN
 	 If @PL_Desc = '' Or @PL_Desc Is Null
 	 Begin
 	  	 Select 'Failed - Missing Production Line'
 	  	 Return (-100)
 	 End
 	 If @PU_Desc = '' Or @PU_Desc Is Null
 	 Begin
 	  	 Select 'Failed - Missing Production Unit'
 	  	 Return (-100)
 	 End
 	 Select @Result_PL_Id = PL_Id
 	   From Prod_Lines
 	  Where PL_Desc = @PL_Desc
 	 
 	 If @Result_PL_Id Is Null
 	   Begin
 	  	 Select 'Failed - Invalid Production Line'
 	  	 Return (-100)
 	   End
 	 Select @Result_PU_Id = PU_Id
 	  From Prod_Units
 	  Where PU_Desc = @PU_Desc And PL_Id = @Result_PL_Id
 	 
 	 If @Result_PU_Id Is Null
 	   Begin
 	  	 Select 'Failed - Invalid Production Unit'
 	  	 Return (-100)
 	   End
 	 
 	 Select @Result_Var_Id = Var_Id
 	    From Variables
 	    Where Var_Desc = @Var_Desc And PU_Id = @Result_PU_Id
 	 If @Result_Var_Id Is Null
 	   Begin
 	  	 Select 'Failed - Invalid Variable'
 	  	 Return (-100)
 	   End
END
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Create Calculation Definition 	   	  	  	  	  	 *
******************************************************************************************************************************************************/
Select  	 @Calculation_Id  	  	  	 = Calculation_Id,
 	 @Comment_Id  	  	  	  	 = Comment_Id,
 	 @Current_Calculation_Type_Id 	  	 = Calculation_Type_Id,
 	 @Current_Trigger_Type_Id 	  	 = Trigger_Type_Id,
 	 @Current_Equation 	  	  	 = LTrim(RTrim(Equation)),
 	 @Current_Script 	  	  	  	 = LTrim(RTrim(Convert(varchar(8000), Script))),
 	 @Current_SP_Name 	 = LTrim(RTrim(Stored_Procedure_Name))
From Calculations
Where LTrim(RTrim(Calculation_Name)) = @Calculation_Name
/* MKW 02/13/02 - If calculation exists, then verify its the same */
If @Calculation_Id Is Not Null
  Begin
     If @Calculation_Type_Id <> @Current_Calculation_Type_Id Or @Trigger_Type_Id <> @Current_Trigger_Type_Id
 	  	  Or (@Calculation_Type_Id = 1 And @Equation <> @Current_Equation) Or (@Calculation_Type_Id = 2 And @SP_Name <> @Current_SP_Name)
 	  	  Or (@Calculation_Type_Id = 3 And (@Script <> @Current_Script and  @Script <> Char(2)))
       Begin
          Select 'Failed - Calculation with given Name and different defination already exists'
          Return (-100)
       End
   End
/* Else create the calculation */
Else
     Begin
      	 If @Comment_Text <> '' And @Comment_Text Is Not Null
          Begin
             Insert Into Comments(User_Id, CS_Id, Comment, Comment_Text, Modified_On)
             Values (1, 1, @Comment_Text, @Comment_Text, dbo.fnServer_CmnGetDate(getUTCdate()))
             Select @Comment_Id = Scope_Identity()
          End
 	    If @Script = Char(2)
 	       Insert into calculations (calculation_name, calculation_desc, calculation_type_id, version, locked,trigger_type_id,Lag_Time,Max_Run_Time,Equation,Stored_Procedure_Name,Comment_Id,Optimize_Calc_Runs)
       	  	  	 values(@Calculation_Name, @Calculation_Desc, @Calculation_Type_Id, @Version, @Locked,@Trigger_Type_Id,@Lag_Time, @Max_Run_Time,@Equation,@SP_Name,@Comment_Id,@iOptimizeRun)
 	  	 Else
 	       Insert into calculations (calculation_name, calculation_desc, calculation_type_id, version, locked,trigger_type_id,Lag_Time,Max_Run_Time,Script,Equation,Stored_Procedure_Name,Comment_Id,Optimize_Calc_Runs)
       	  	  	 values(@Calculation_Name, @Calculation_Desc, @Calculation_Type_Id, @Version, @Locked,@Trigger_Type_Id,@Lag_Time, @Max_Run_Time,@Script,@Equation,@SP_Name,@Comment_Id,@iOptimizeRun)
 	  	 Select @Calculation_Id = Scope_Identity()
 	  	 If @Calculation_Id = 0 or @Calculation_Id is null
 	  	   Begin
 	  	  	 Select 'Failed - Unable to create Calculation'
 	  	  	 Return (-100)
 	  	   End
     End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Assign to variable 	  	   	  	  	  	  	 *
******************************************************************************************************************************************************/
IF @Result_Var_Id Is Not NULL
BEGIN
 	 Select @Variable_Calculation_Id = Calculation_Id 
 	 From Variables 
 	 Where Var_Id = @Result_Var_Id
 	 If @Variable_Calculation_Id Is Null Or @Variable_Calculation_Id <> @Calculation_Id
 	   Begin
 	      /* Clear out the previously assigned calculation inputs against this variable */
 	      If @Variable_Calculation_Id <> @Calculation_Id
 	         Begin
 	      	  	 Execute spEMCC_ByCalcId 29, @Calculation_Id, @User_Id
 	         End
 	      Update Variables_Base Set DS_Id = 16, Calculation_Id = @Calculation_Id Where Var_Id= @Result_Var_Id
 	   End
END
If @Script = Char(2) -- return calcid to client
Begin
 	   select Char(2) +  Convert(nVarChar(10),@Calculation_Id)
 	   Return (-100)
End
Return(0)
