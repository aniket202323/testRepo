create procedure dbo.spSupport_VerifyDB_StaticTableCnt
@Tblname varchar(100),
@TrueNum int,
@IdFieldName varchar(100) = NULL,
@MaxId int = NULL
as
Declare
  @Num int,
  @Statement varchar(255),
  @Msg varchar(255),
  @TableId int
SELECT @Tblname = 'dbo.' + @Tblname
Select @TableId = NULL
Select @TableId = object_id(@Tblname)
If (@TableId Is NULL)
  Begin
    Select @Msg = '-- Warning: Missing Static Table [' + @Tblname + ']'
    Print @Msg
    Return
  End
Create Table #GlobalValue (Num int NULL)
If (@MaxId Is NULL)
  Select @Statement = 'Insert Into #GlobalValue(Num) (Select Count(*) From ' + @TblName + ')'
Else
  Select @Statement = 'Insert Into #GlobalValue(Num) (Select Count(*) From ' + @TblName + ' Where ' + @IdFieldName + ' <= ' + Convert(varchar(10),@MaxId) + ')'
Execute (@Statement)
Select @Num = 0
Select @Num = Num From #GlobalValue
If (@Num Is NULL)
  Select @Num = 0
Drop Table #GlobalValue
If (@Num <> @TrueNum)
  Begin
    Select @Msg = '-- Warning: Static Table [' + @Tblname + '] Has [' + Convert(varchar(10),@Num) + '] Rows. It Should Have [' + Convert(varchar(10),@TrueNum) + '] Rows'
    Print @Msg
  End
