CREATE PROCEDURE dbo.spSupport_CalcGUIDFix_DropGUID
AS 
--Drop all unknown Defaults
set nocount on 
--Drop the Calculation_GUID column
If ((select count(*) from sys.syscolumns c join sys.sysobjects o on c.id = o.id and o.name = 'calculations' where c.name = 'CALCULATION_GUID') > 0)
  exec('alter table calculations drop column calculation_guid')
If ((select count(*) from sys.syscolumns c join sys.sysobjects o on c.id = o.id and o.name = 'Calculation_Dependencies' where c.name = 'CALCULATION_GUID') > 0)
  exec('alter table Calculation_Dependencies drop column calculation_guid')
If ((select count(*) from sys.syscolumns c join sys.sysobjects o on c.id = o.id and o.name = 'Calculation_Inputs' where c.name = 'CALCULATION_GUID') > 0)
  exec('alter table Calculation_Inputs drop column calculation_guid')
If ((select count(*) from sys.syscolumns c join sys.sysobjects o on c.id = o.id and o.name = 'Variables' where c.name = 'CALCULATION_GUID') > 0)
  exec('alter table Variables drop column calculation_guid')
If ((select count(*) from sys.syscolumns c join sys.sysobjects o on c.id = o.id and o.name = 'Topics' where c.name = 'CALCULATION_GUID') > 0)
  exec('alter table Topics drop column calculation_guid')
--Drop the defaults from the Calculation_Id add
if exists (select * from sys.sysobjects where id = object_id(N'[dbo].[DEFAULT_GUIDFIX_1]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
  exec('alter table Calculation_Dependencies drop constraint DEFAULT_GUIDFIX_1')
if exists (select * from sys.sysobjects where id = object_id(N'[dbo].[DEFAULT_GUIDFIX_2]') and OBJECTPROPERTY(id, N'IsConstraint') = 1)
  exec('alter table Calculation_Inputs drop constraint DEFAULT_GUIDFIX_2')
set nocount oFF
