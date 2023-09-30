CREATE PROCEDURE dbo.spSupport_CalcGUIDFix_AddCalcId
AS 
set nocount on 
--Add the new Calculation_Id column to all tables with the Calculation_GUID column
EXEC ('alter table calculations
  add Calculation_Id int IDENTITY(1,1) NOT NULL')
EXEC ('alter table Calculation_Dependencies
  add Calculation_Id int NOT NULL constraint DEFAULT_GUIDFIX_1 DEFAULT(-1)') --name the default here so I can drop it later
EXEC ('alter table Calculation_Inputs
  add Calculation_Id int NOT NULL constraint DEFAULT_GUIDFIX_2 DEFAULT(-1)') --name the default here so I can drop it later
EXEC ('alter table Variables
  add Calculation_Id int NULL ')
EXEC ('alter table Topics
  add Calculation_Id int NULL ')
--Set the Calculation_Id column based on the old Calculation_GUID column
EXEC ('Update Calculation_Dependencies 
  Set Calculation_Id = (Select Calculation_Id from Calculations c Where c.Calculation_GUID = Calculation_Dependencies.Calculation_GUID)')
EXEC ('Update Calculation_Inputs 
  Set Calculation_Id = (Select Calculation_Id from Calculations c Where c.Calculation_GUID = Calculation_Inputs.Calculation_GUID)')
EXEC ('Update Variables 
  Set Calculation_Id = (Select Calculation_Id from Calculations c Where c.Calculation_GUID = Variables.Calculation_GUID)')
EXEC ('Update Topics 
  Set Calculation_Id = (Select Calculation_Id from Calculations c Where c.Calculation_GUID = Topics.Calculation_GUID)')
set nocount oFF
