CREATE PROCEDURE dbo.spSupport_ReviseSheet
@FromSheetName varchar(50),
@ToSheetName varchar(50)
AS
declare @FromSheet int
declare @ToSheet int
declare @Msg varchar(200)
select @FromSheet = Null
Select @FromSheet = Sheet_Id
  From Sheets
  Where Sheet_Desc = @FromSheetName
If @FromSheet Is Null 
  Begin
    Select @Msg = 'Error: From Sheet Not Found [' + @FromSheetName + ']'
    Print @Msg
    Return
  End
select @ToSheet = Null
Select @ToSheet = Sheet_Id
  From Sheets
  Where Sheet_Desc = @ToSheetName
If @ToSheet Is Null
  Begin
    Select @Msg = 'Error: To Sheet Not Found [' + @ToSheetName + ']'
    Print @Msg
    Return
  End
begin transaction
delete from sheet_variables where sheet_id = @ToSheet
Insert Into sheet_variables (sheet_id, var_id, var_order)
  select  @ToSheet, var_id, var_order
    From Sheet_Variables Where sheet_id = @FromSheet
commit transaction
