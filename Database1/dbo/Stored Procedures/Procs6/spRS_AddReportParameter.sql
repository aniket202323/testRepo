CREATE PROCEDURE dbo.spRS_AddReportParameter
@RP_Name varchar(50),
@RPT_Id int, 
@RPG_Id int, 
@Description varchar(900),
@Default_Value varchar(7000),
@Is_Default int,
@SP_Name varchar(50),
@MultiSelect int,
@Exists int output
 AS
Declare @MyError int
Select @MyError = 0
Select @Exists = RP_ID
From Report_Parameters
Where RP_Name = @RP_Name
If @Exists Is Null
  Begin
    Insert Into Report_Parameters(RP_Name, RPT_Id, RPG_Id, Description, Default_Value, Is_Default, MultiSelect, SPName)
    Values(@RP_Name, @RPT_Id, @RPG_Id, @Description, @Default_Value, @Is_Default, @MultiSelect, @SP_Name)
    Select @Exists = Scope_Identity()
    If @@Error <> 0
      Return (1) -- Error
    Else
      Return (0) -- new row added
  End
Else
  Begin
    Update Report_Parameters SET
     	 Description = @Description,
        Default_Value = @Default_Value, 
        Is_Default = @Is_Default,
 	 spName = @SP_Name,
 	 MultiSelect = @MultiSelect
    Where RP_Id = @Exists
    If @@Error <> 0
      Return (3)  -- Error updating existing row
    Else
      Return (2)  -- update existing Row
  End
