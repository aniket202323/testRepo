/*
set nocount on
exec spRS_GetValidValues 'spRS_GetProdLines', 0
exec spRS_GetValidValues null, 5
*/
CREATE PROCEDURE dbo.spRS_GetValidValues
@SPName varchar(25) = Null,
@Id int
 AS
Declare @SQLString varchar(255)
Declare @Temp_Table TABLE(
    Id int,
    Name VarChar(50),
    Switch int)
If Not(@SPName Is Null)
  Begin  -- Call spLocal_...
    Execute @SPName
  End
Else
  Begin
    If @Id = 1 -- Printers
      Begin
        Insert Into @Temp_Table(Id, Name, Switch)
        Select Printer_Id 'ID', Printer_Name 'Name', 0 From Report_Printers
      End
    Else If @Id = 2 -- PrintStyles
      Begin
        Insert Into @Temp_Table(Id, Name, Switch)
        Select Style_Id 'ID', Style_Name 'Name', 0 From Report_Print_Styles
      End
    Else If @Id = 3  -- Time Option
      Begin
        Insert Into @Temp_Table(Id, Name, Switch)
 	 Values(0, 'User Defined', 0)
        Insert Into @Temp_Table(Id, Name, Switch)
 	 select RRD_Id, Default_Prompt_Desc, 0 from report_relative_dates where date_Type_Id = 3
      End
    Else If @Id = 4 -- Users
      Begin
        Insert Into @Temp_Table(Id, Name, Switch)
        Select User_id, Username, 0 From Users
      End
    Else If @Id = 5 -- VariableSelection
      Begin
        Insert Into @Temp_Table(Id, Name, Switch)
        Select 1, 'All', 1
        Insert Into @Temp_Table(Id, Name, Switch)
        Select 2, 'Event', 1 
        Insert Into @Temp_Table(Id, Name, Switch)
        Select 3, 'Time', 1 
      End
    Select Id, Name, Switch from @Temp_Table
  End
