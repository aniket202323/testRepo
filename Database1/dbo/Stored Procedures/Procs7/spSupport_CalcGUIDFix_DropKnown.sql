CREATE PROCEDURE dbo.spSupport_CalcGUIDFix_DropKnown
AS 
set nocount on 
--Drop all known FKs/Defaults/Keys - MUST BE IN THIS ORDER!!!
if exists (select * from sys.sysobjects where id = object_id(N'[dbo].[DF_Calculations_Calculation_GUID]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
  EXEC('alter table calculations drop constraint DF_Calculations_Calculation_GUID')
if exists (select * from sys.sysobjects where id = object_id(N'[dbo].[FK_Calculation_Dependencies_Calculations]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
  EXEC('alter table Calculation_Dependencies drop constraint FK_Calculation_Dependencies_Calculations')
if exists (select * from sys.sysobjects where id = object_id(N'[dbo].[FK_Calculation_Inputs_Calculations]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
  EXEC('alter table Calculation_Inputs drop constraint FK_Calculation_Inputs_Calculations')
if exists (select * from sys.sysobjects where id = object_id(N'[dbo].[PK_Calculations]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
  EXEC('alter table calculations drop constraint PK_Calculations')
if exists (select * from sys.sysobjects where id = object_id(N'[dbo].[DF_Calculation_Dependencies_Calculation_GUID]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
  EXEC('alter table Calculation_Dependencies drop constraint DF_Calculation_Dependencies_Calculation_GUID')
if (select count(*) from sys.sysindexes where name = 'CalculationInputs_IDX_IdGuid') > 0
  EXEC('Drop Index Calculation_Inputs.CalculationInputs_IDX_IdGuid')
set nocount oFF
