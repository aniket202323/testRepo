CREATE PROCEDURE dbo.spEM_IEImportVariableCalculations
 	 @PL_Desc 	  	 nvarchar(50),
 	 @PU_Desc 	  	 nvarchar(50),
 	 @Var_Desc 	  	 nvarchar(50),
 	 @DS_Desc 	  	 nvarchar(50),
 	 @PL_Des2 	  	 nvarchar(50),
 	 @PU_Des2 	  	 nvarchar(50),
 	 @Var_Des2 	  	 nvarchar(50),
 	 @C_Name 	  	  	 nvarchar(255),
 	 @C_Description 	 nvarchar(255),
 	 @C_Type 	  	  	 nVarChar(100),
 	 @Equation 	  	 nvarchar(255),
 	 @Trigger_Type 	 nVarChar(100),
 	 @Lag_Time 	  	 nVarChar(10),
 	 @Max_Run_Time 	 nVarChar(10),
 	 @Alias 	  	  	 nVarChar(100),
 	 @Input_Name 	  	 nVarChar(100),
 	 @Entity 	  	  	 nVarChar(100),
 	 @Attribute 	  	 nVarChar(100),
 	 @Input_Order 	 nVarChar(10),
 	 @Default_Value 	 nvarchar(1000), 	 
 	 @Optional 	  	 nVarChar(10),
 	 @Sp_Name 	  	 nvarchar(255),
 	 @Script 	  	  	 nvarchar(255),
 	 @Comment 	  	 nvarchar(255),
 	 @Constant 	  	 nvarchar(1000),
 	 @OptimizeRun 	 nVarChar(10),
 	 @Version 	  	 nVarChar(100),
 	 @NonTrigger 	  	 nVarChar(10),
 	 @User_Id 	  	 Int
As
Select  @DS_Desc = Ltrim(Rtrim(@DS_Desc))
If @DS_Desc = 'Aliased'
  Execute spEM_IEImportAliased @PL_Desc,@PU_Desc,@Var_Desc,@PL_Des2,@PU_Des2,@Var_Des2,@User_Id
--Else If @DS_Desc = 'Base Variable'
-- Execute spEM_IEImportBaseVariable @PL_Desc,@PU_Desc,@Var_Desc,@PL_Des2,@PU_Des2,@Var_Des2,@User_Id
Else If @DS_Desc = 'CalculationMgr'
  Execute spEM_IEImportCalculation  	 @PL_Desc,@PU_Desc,@Var_Desc,@C_Name,@C_Description,@C_Type,@Equation,@Trigger_Type,@Lag_Time,@Max_Run_Time,@Version, '0',@Sp_Name,@Script,@Comment,@OptimizeRun,@User_Id
Else If @DS_Desc = 'Calculation Input'
  Execute spEM_IEImportCalculationInputs  @PL_Desc,@PU_Desc,@Var_Desc,@PL_Des2,@PU_Des2,@Var_Des2,@C_Name,@Alias,@Input_Name,@Entity,@Attribute,@Input_Order,@Default_Value,@Optional,@Constant,@NonTrigger, @User_Id
Else If @DS_Desc = 'Calculation Dependency'
  Execute spEM_IEImportCalculationDependency  @PL_Desc,@PU_Desc,@Var_Desc,@PL_Des2,@PU_Des2,@Var_Des2,@C_Name,@Input_Name,@Attribute,@Optional,@User_Id
Else If @DS_Desc = 'Additional Dependency'
  Execute spEM_IEImportAdditionalDependency @PL_Desc,@PU_Desc,@Var_Desc,@PL_Des2,@PU_Des2,@Var_Des2,@C_Name,@Attribute,@User_Id
Else
  Select 'Failed - Invalid Calculation type'
