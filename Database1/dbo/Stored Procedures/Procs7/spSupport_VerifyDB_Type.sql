create procedure dbo.spSupport_VerifyDB_Type
@Typename varchar(100),
@ActualTypeName varchar(100),
@Nullability varchar(50)
AS
Declare
  @TypeId int,
  @Statement varchar(2000)
Select @TypeId = NULL
Select @TypeId = Usertype From sys.systypes Where (Name = @TypeName) And (Usertype > 100)
If (@TypeId Is NULL)
  Begin
    Select @Statement = 'Execute sp_addtype ''' + @TypeName + ''',''' + @ActualTypeName + ''',''' + @nullability + ''''
    Execute (@Statement)
    Select @Statement = '-- Added Type [' + @TypeName + ']'
    Print @Statement
    Return
  End
