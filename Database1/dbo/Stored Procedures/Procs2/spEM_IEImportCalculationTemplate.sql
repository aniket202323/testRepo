CREATE PROCEDURE dbo.spEM_IEImportCalculationTemplate
 	 @DS_Desc 	  	 nvarchar(50),
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
 	 @Default_Value 	 nVarChar(100), 	 
 	 @Optional 	  	 nVarChar(10),
 	 @Sp_Name 	  	 nvarchar(255),
 	 @Script 	  	  	 nvarchar(255),
 	 @Comment 	  	 nvarchar(255),
 	 @OptimizeCalc 	 nVarChar(10),
 	 @Version 	  	 nVarChar(100),
 	 @NonTriggering 	 nVarChar(10),
 	 @User_Id 	  	 Int
As
Select  @DS_Desc = Ltrim(Rtrim(@DS_Desc))
If @DS_Desc = 'CalculationMgr'
  Execute spEM_IEImportCalculation  	 Null,Null,Null,@C_Name,@C_Description,@C_Type,@Equation,@Trigger_Type,@Lag_Time,@Max_Run_Time,@Version,'0',@Sp_Name,@Script,@Comment,@OptimizeCalc,@User_Id
Else If @DS_Desc = 'Calculation Input'
  Execute spEM_IEImportCalculationInputs  Null,Null,Null,Null,Null,Null,@C_Name,@Alias,@Input_Name,@Entity,@Attribute,@Input_Order,@Default_Value,@Optional,Null,@NonTriggering, @User_Id
Else If @DS_Desc = 'Calculation Dependency'
  Execute spEM_IEImportCalculationDependency  Null,Null,Null,Null,Null,Null,@C_Name,@Input_Name,@Attribute,@Optional,@User_Id
Else
  Select 'Failed - Invalid Calculation type'
