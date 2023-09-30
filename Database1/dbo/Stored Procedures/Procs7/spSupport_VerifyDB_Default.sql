create procedure dbo.spSupport_VerifyDB_Default
@TableName varchar(100),
@FieldName varchar(100),
@TrueDefName varchar(100),
@TrueDefValue varchar(100)
AS
Declare
  @TableId int,
  @ColId int,
  @DefId int,
  @DefName varchar(100),
  @DefValue varchar(100),
  @Statement varchar(255),
  @ShouldCreate int,
  @TheDef varchar(100)
Select @ShouldCreate = 0
SELECT @TableName = 'dbo.' + @TableName
Select @TableId = object_id(@TableName) 
If (@TableId Is NULL)
  Return
Select @ColId = NULL
Select @DefId = NULL
Select @ColId = Id, @DefId = cDefault From sys.syscolumns Where (Id = @TableId) And (Name = @FieldName)
If (@ColId Is NULL)
  Return
If (@DefId = 0)
  Select @DefId = NULL
If (@DefId Is Not NULL)
  Begin
    Select @DefName = Name From sys.sysobjects Where (Id = @DefId) And (Type = 'D')
    Select @DefValue = text From sys.syscomments Where Id = @DefId
    If (@TrueDefName <> @DefName)
      Select @ShouldCreate = 1
    If (@TrueDefValue <> @DefValue) and ('(' + @TrueDefValue + ')' <>  @DefValue )
      Select @ShouldCreate = 1
    If (@ShouldCreate = 1)
      Begin
        Select @Statement = 'Alter Table ' + @TableName + ' DROP CONSTRAINT ' + @DefName
        Execute (@Statement)
      End
  End
Else
  Select @ShouldCreate = 1
If (@ShouldCreate = 1)
  Begin
    Select @Statement = 'Alter Table ' + @TableName + ' WITH NOCHECK ADD CONSTRAINT ' + @TrueDefName + ' DEFAULT' + @TrueDefValue + ' FOR ' + @FieldName
    Execute (@Statement)
    Select @Statement = 'Alter Table ' + @TableName + ' Disable Trigger All'
    Execute (@Statement)
    Select @TheDef = SubString(@TrueDefValue,2,Len(@TrueDefValue) - 2)
    Select @Statement = 'Update ' + @TableName + ' Set ' + @FieldName + ' = ' + @TheDef + ' Where ' + @FieldName + ' IS NULL'
    Execute (@Statement)
    Select @Statement = 'Alter Table ' + @TableName + ' Enable Trigger All'
    Execute (@Statement)
    Select @Statement = '-- Added/Replaced Default [' + @TableName + '] [' + @FieldName + '] [' + @TrueDefName + '] [' + @TheDef + ']'
    Print @Statement
  End
