CREATE PROCEDURE dbo.spSupport_CalcGUIDFix_DropUnknown
AS 
--Drop all unknown Defaults
set nocount on 
Declare
  @@KeyId int,
  @Msg varchar(2000),
  @@KeyName varchar(100),
  @KeyNumber int,
  @@TableName varchar(100),
  @@Name sysname,
  @@RefTableName varchar(100),
  @ReferencingTableId int,
  @ReferencedTableId int,
  @ReferencingColId int,
  @ReferencedColId int,
  @ReferencingColName varchar(100),
  @ReferencedColName varchar(100),
  @@ReferencingCol1 varchar(100),
  @@ReferencedCol1 varchar(100),
  @@ReferencingCol2 varchar(100),
  @@ReferencedCol2 varchar(100),
  @@ReferencingCol3 varchar(100),
  @@ReferencedCol3 varchar(100)
Declare DF_Cursor INSENSITIVE CURSOR
  For (
  Select TableName = c.Name, a.Name
    From sys.sysobjects a
    Join sys.syscolumns b on b.cdefault = a.id and b.name = 'calculation_guid'
    Join sys.sysobjects c on c.Id = b.Id
    Join syscomments d on d.Id = a.Id
    Where a.Type = 'D'
    )
  For Read Only
  Open DF_Cursor  
DF_Loop:
  Fetch Next From DF_Cursor Into @@TableName, @@Name
  If (@@Fetch_Status = 0)
    Begin
      Select @Msg = 'Alter Table ' + @@TableName + ' DROP CONSTRAINT  ' + @@Name 
      EXEC (@Msg)
      Goto DF_Loop
    End
Close DF_Cursor
Deallocate DF_Cursor
--Use Tom's logic to drop any unknown FKs
Create Table #FKeys (TableName varchar(100) NULL, KeyName varchar(100), KeyId int, RefTableName varchar(100) NULL, ReferencingCol1 varchar(100) NULL,ReferencedCol1 varchar(100) NULL,ReferencingCol2 varchar(100) NULL,ReferencedCol2 varchar(100) NULL,ReferencingCol3 varchar(100) NULL,ReferencedCol3 varchar(100) NULL)
Insert Into #FKeys(KeyName,KeyId) (Select Name,Id From sys.sysobjects Where Type = 'F')
Update #FKeys
  Set #FKeys.TableName = o.Name
  From #FKeys k, sys.sysforeignkeys f, sys.sysobjects o
  Where (k.KeyId = f.constid) And (f.fkeyid = o.id) 
Update #FKeys
  Set #FKeys.RefTableName = o.Name
  From #FKeys k, sys.sysforeignkeys f, sys.sysobjects o
  Where (k.KeyId = f.constid) And (f.rkeyid = o.id)
Delete #FKeys where reftablename <> 'Calculations'
Declare FKey_Cursor INSENSITIVE CURSOR
  For (Select KeyId,KeyName From #FKeys)
  For Read Only
  Open FKey_Cursor  
FKey_Loop:
  Fetch Next From FKey_Cursor Into @@KeyId,@@KeyName
  If (@@Fetch_Status = 0)
    Begin
      Select @KeyNumber = 0
      FKeyNum_Loop:
      Select @KeyNumber = @KeyNumber + 1
      Select @ReferencingTableId = NULL
      Select @ReferencedTableId = NULL
      Select @ReferencingColId = NULL
      Select @ReferencedColId = NULL
      Select @ReferencingTableId = fkeyid,
 	      @ReferencedTableId = rkeyid,
             @ReferencingColId = fkey,
             @ReferencedColId = rkey 
        From sys.sysforeignkeys 
        Where (constid = @@KeyId) And (Keyno = @KeyNumber)
      If (@ReferencingTableId Is Not NULL) And (@ReferencedTableId Is Not NULL) And (@ReferencingColId Is Not NULL) And (@ReferencedColId Is Not NULL)
        Begin
          Select @ReferencingColName = NULL
 	   Select @ReferencedColName = NULL
          Select @ReferencingColName = Name From sys.syscolumns Where (Id = @ReferencingTableId) And (Colid = @ReferencingColId)
          Select @ReferencedColName = Name From sys.syscolumns Where (Id = @ReferencedTableId) And (Colid = @ReferencedColId)
          If (@ReferencingColName Is Not NULL) And (@ReferencedColName Is Not NULL)
            Begin
              If (@KeyNumber = 1)
                Update #FKeys Set ReferencingCol1 = @ReferencingColName, ReferencedCol1 = @ReferencedColName Where (KeyId = @@KeyId)                                   
              If (@KeyNumber = 2)
                Update #FKeys Set ReferencingCol2 = @ReferencingColName, ReferencedCol2 = @ReferencedColName Where (KeyId = @@KeyId)                                   
              If (@KeyNumber = 3)
                Update #FKeys Set ReferencingCol3 = @ReferencingColName, ReferencedCol3 = @ReferencedColName Where (KeyId = @@KeyId)                                   
       	       Goto FKeyNum_Loop
            End
        End
      Goto FKey_Loop
    End
Close FKey_Cursor
Deallocate FKey_Cursor
Update #FKeys Set ReferencingCol2 = '' Where ReferencingCol2 Is NULL
Update #FKeys Set ReferencedCol2 = '' Where ReferencedCol2 Is NULL
Update #FKeys Set ReferencingCol3 = '' Where ReferencingCol3 Is NULL
Update #FKeys Set ReferencedCol3 = '' Where ReferencedCol3 Is NULL
Declare FKey2_Cursor INSENSITIVE CURSOR
  For (Select TableName,KeyName From #FKeys
    where ReferencingCol1 = 'Calculation_Guid' or 
          ReferencingCol2 = 'Calculation_Guid' or 
          ReferencingCol3 = 'Calculation_Guid'
    )
  For Read Only
  Open FKey2_Cursor  
FKey2_Loop:
  Fetch Next From FKey2_Cursor Into @@TableName, @@KeyName
  If (@@Fetch_Status = 0)
    Begin
      Select @Msg = 'Alter Table ' + @@TableName + ' DROP CONSTRAINT  ' + @@KeyName 
      EXEC (@Msg)
      Goto FKey2_Loop
    End
Close FKey2_Cursor
Deallocate FKey2_Cursor
DROP TABLE #Fkeys
--Drop any unknown Indecies
Create Table #KeyColumns (TableName varchar(100), KeyName varchar(100), ColumnName varchar(100), Pos int)
Insert Into #KeyColumns (TableName,KeyName,ColumnName,Pos)
(select b.name,
       c.Name,
       d.Name,
       a.keyno
  from sysindexkeys a
  join sys.sysobjects b on (b.id = a.id) and (b.type = 'U')  
  join sys.sysindexes c on (c.id = a.id) and (c.indid = a.indid) and (c.Id > 255)
  join sys.syscolumns d on (d.id = b.id) and (d.colid = a.colid) and d.name = 'Calculation_GUID'
  where (a.IndId <> 255) And (a.IndId <> 0) And (substring(c.name,1,1) <> '_'))
Declare IKey_Cursor INSENSITIVE CURSOR
  For (Select TableName,KeyName From #KeyColumns
    )
  For Read Only
  Open IKey_Cursor  
IKey_Loop:
  Fetch Next From IKey_Cursor Into @@TableName, @@KeyName
  If (@@Fetch_Status = 0)
    Begin
      Select @Msg = 'Drop Index ' + @@TableName + '.' + @@KeyName 
      EXEC (@Msg)
      Goto IKey_Loop
    End
Close IKey_Cursor
Deallocate IKey_Cursor
DROP TABLE #KeyColumns
set nocount oFF
