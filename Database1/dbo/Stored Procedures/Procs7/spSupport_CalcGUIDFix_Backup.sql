CREATE PROCEDURE dbo.spSupport_CalcGUIDFix_Backup
AS 
set nocount on 
if NOT exists (select * from sys.sysobjects where id = object_id(N'[dbo].[TMPCalcGUIDFix_Calculation_Dependencies]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
  CREATE TABLE [dbo].[TMPCalcGUIDFix_Calculation_Dependencies] (
 	 [Calc_Dependency_Id] [int] NULL ,
 	 [Calc_GUID] [uniqueidentifier] NULL ,
 	 [Name] [Varchar_Desc] NULL ,
 	 [Calc_Dependency_Scope_Id] [int] NULL ,
 	 [Optional] [bit] NULL 
) 
EXEC('
Insert Into [dbo].[TMPCalcGUIDFix_Calculation_Dependencies] 
  Select 
   [Calc_Dependency_Id] ,
   [Calculation_GUID] ,
   [Name] ,
   [Calc_Dependency_Scope_Id] ,
   [Optional]
 from [dbo].[Calculation_Dependencies]')
if NOT exists (select * from sys.sysobjects where id = object_id(N'[dbo].[TMPCalcGUIDFix_Calculation_Inputs]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
--  DROP TABLE [dbo].[TMPCalcGUIDFix_Calculation_Inputs] 
  CREATE TABLE [dbo].[TMPCalcGUIDFix_Calculation_Inputs] (
 	 [Calc_Input_Id] [int] NULL ,
 	 [Calc_GUID] [uniqueidentifier] NULL ,
 	 [Alias] [Varchar_Desc] NULL ,
 	 [Input_Name] [Varchar_Desc] NULL ,
 	 [Calc_Input_Entity_Id] [int] NULL ,
 	 [Calc_Input_Attribute_Id] [int] NULL ,
 	 [Calc_Input_Order] [int] NULL ,
 	 [Default_Value] [Varchar_Value] NULL ,
 	 [Optional] [bit] NULL 
) 
EXEC('Insert Into [dbo].[TMPCalcGUIDFix_Calculation_Inputs] 
  Select 
 	 [Calc_Input_Id] ,
 	 [Calculation_GUID] ,
 	 [Alias] ,
 	 [Input_Name] ,
 	 [Calc_Input_Entity_Id] ,
 	 [Calc_Input_Attribute_Id] ,
 	 [Calc_Input_Order] ,
 	 [Default_Value] ,
 	 [Optional] 
    FROM [dbo].[Calculation_Inputs] ')
if NOT exists (select * from sys.sysobjects where id = object_id(N'[dbo].[TMPCalcGUIDFix_Calculations]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
--  DROP TABLE [dbo].[TMPCalcGUIDFix_Calculations] 
  CREATE TABLE [dbo].[TMPCalcGUIDFix_Calculations] (
 	 [Calc_GUID] [uniqueidentifier] NULL ,
 	 [Calculation_Name] [varchar] (255) NULL ,
 	 [Calculation_Desc] [varchar] (255) NULL ,
 	 [Calculation_Type_Id] [int] NULL ,
 	 [Equation] [varchar] (255) NULL ,
 	 [Script] [text] NULL ,
 	 [Stored_Procedure_Name] [Varchar_Desc] NULL ,
 	 [Version] [varchar] (10) NULL ,
 	 [Locked] [bit] NULL ,
 	 [Comment_Id] [int] NULL ,
 	 [Lag_Time] [int] NULL ,
 	 [Trigger_Type_Id] [int] NULL ,
 	 [Max_Run_Time] [int] NULL 
) 
EXEC('Insert Into [dbo].[TMPCalcGUIDFix_Calculations] 
  Select 
 	 [Calculation_GUID] ,
 	 [Calculation_Name] ,
 	 [Calculation_Desc] ,
 	 [Calculation_Type_Id] ,
 	 [Equation] ,
 	 [Script] ,
 	 [Stored_Procedure_Name] ,
 	 [Version] ,
 	 [Locked] ,
 	 [Comment_Id] ,
 	 [Lag_Time] ,
 	 [Trigger_Type_Id] ,
 	 [Max_Run_Time] 
 	 FROM [dbo].[Calculations] ')
if NOT exists (select * from sys.sysobjects where id = object_id(N'[dbo].[TMPCalcGUIDFix_Topics]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
--  DROP TABLE [dbo].[TMPCalcGUIDFix_Topics] 
  CREATE TABLE [dbo].[TMPCalcGUIDFix_Topics] (
 	 [Topic_Id] [int] NULL ,
 	 [Calc_GUID] [uniqueidentifier] NULL 
)
EXEC('Insert Into [dbo].[TMPCalcGUIDFix_Topics] 
  Select 
 	 [Topic_Id] ,
 	 [Calculation_GUID] 
 	 FROM [dbo].[Topics] ')
if NOT exists (select * from sys.sysobjects where id = object_id(N'[dbo].[TMPCalcGUIDFix_Variables]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
--  DROP TABLE [dbo].[TMPCalcGUIDFix_Variables] 
  CREATE TABLE [dbo].[TMPCalcGUIDFix_Variables] (
 	 [Var_Id] [int] NULL ,
 	 [Calc_GUID] [uniqueidentifier] NULL 
) 
EXEC('Insert Into [dbo].[TMPCalcGUIDFix_Variables]
  Select 
 	 [Var_Id] ,
 	 [Calculation_GUID] 
 	 FROM [dbo].[Variables]') 
set nocount oFF
