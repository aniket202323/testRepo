CREATE PROCEDURE dbo.spRS_GetReportServerSettings
@Name varchar(20) = Null
AS
If @Name Is Null
  Begin
    Select * 
    From Report_Server_Settings
  End
Else
  Begin
    Select Value
    From Report_Server_Settings
    Where Name = @Name
  End
