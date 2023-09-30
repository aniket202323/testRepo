CREATE PROCEDURE dbo.spRS_SetReportServerSetting
@Name varchar(20),
@Value varchar(255)
AS
Select *
From Report_Server_Settings
Where Name = @Name
If @@RowCount > 0
  Begin
    Update Report_Server_Settings
    Set Value = @Value
    Where Name = @Name   
  End
Else
  Begin
    Insert Into Report_Server_Settings(
      Name,
      Value)
    Values(
      @Name,
      @Value)
  End
