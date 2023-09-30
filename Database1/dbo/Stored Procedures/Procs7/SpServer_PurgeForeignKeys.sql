Create Procedure dbo.SpServer_PurgeForeignKeys
AS
Declare
  @@FKeyId int,
  @KeyName nVarChar(255),
  @ActualTableName nVarChar(255),
  @@ActualTableId int,
  @Msg nVarChar(1000),
  @Cmd nVarChar(1000)
Declare FKey_Cursor INSENSITIVE CURSOR
  For (Select constid,fkeyid from sysforeignkeys where rkeyid in (Select Id From sysobjects Where (Name In ('Comments','Array_Data','Tests','Test_History')) And (Type = 'U')))
  For Read Only
  Open FKey_Cursor  
Fetch_Loop:
  Fetch Next From FKey_Cursor Into @@FKeyId,@@ActualTableId
  If (@@Fetch_Status = 0)
    Begin
      Select @Keyname = Name from sysobjects where id = @@FKeyId
      Select @ActualTableName = Name from sysobjects where (id = @@ActualTableId) And (type = 'U')
      Print 'Warning: Dropping Constraint [' + @Keyname + ']'
      Select @Cmd = 'Alter Table dbo.' + @ActualTableName + ' DROP CONSTRAINT ' + @Keyname
      Execute(@Cmd)
      Goto Fetch_Loop 
    End
Close FKey_Cursor
Deallocate FKey_Cursor
