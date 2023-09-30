CREATE PROCEDURE dbo.spServer_CmnTableRowCounts
AS
Set Nocount On
Declare
  @@Tablename nVarChar(100),
  @NumRows int,
  @SQLText nvarchar(500)
Create Table #RowCounts(TableName nvarchar(60), NumRows int)
Declare Table_Cursor INSENSITIVE CURSOR 
  For Select Name From sysobjects Where Type = 'U'
  For Read Only
  Open Table_Cursor  
Table_Loop:
  Fetch Next From Table_Cursor Into @@TableName
  If (@@Fetch_Status = 0)
    Begin
      Select @SQLText = 'Insert Into #RowCounts(TableName,NumRows) Select "' + @@TableName + '" , Count(*) From ' + @@TableName
      Execute (@SQLText)
      Goto Table_Loop
    End
Close Table_Cursor 
Deallocate Table_Cursor
Select TableName,NumRows From #RowCounts Order By NumRows Desc
Drop Table #RowCounts
