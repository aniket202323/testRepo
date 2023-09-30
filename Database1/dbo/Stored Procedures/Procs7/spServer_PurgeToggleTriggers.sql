CREATE PROCEDURE dbo.spServer_PurgeToggleTriggers
@Password nVarChar(255),
@TurnOn int
AS
Declare
  @@Id int,
  @TableName nVarChar(100),
  @Command nvarchar(500)
If (@TurnOn <> 1) And ((@Password Is NULL) Or (@Password <> 'EverythingIsShutdown-ForSure!!!'))
  return(0)
Declare @TablesWithTriggers Table(Id int)
Insert Into @TablesWithTriggers (Id) (Select Distinct(Parent_Obj) From sysobjects Where Type = 'TR')
Declare Table_Cursor INSENSITIVE CURSOR
  For (Select Id from @TablesWithTriggers) 
  For Read Only
  Open Table_Cursor  
Fetch_Loop:
  Fetch Next From Table_Cursor Into @@Id
  If (@@Fetch_Status = 0)
    Begin
      Select @Tablename = Name From sysobjects Where (Id = @@Id)
      If (@TurnOn = 1)
        Select @Command = 'Alter Table ' + @Tablename + ' Enable Trigger ALL'
      Else
        Select @Command = 'Alter Table ' + @Tablename + ' Disable Trigger ALL'
      Execute(@Command)
      Goto Fetch_Loop
    End
Close Table_Cursor 
Deallocate Table_Cursor
Return(1)
