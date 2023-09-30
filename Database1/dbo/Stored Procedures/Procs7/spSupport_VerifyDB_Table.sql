create procedure dbo.spSupport_VerifyDB_Table
@Tblname varchar(100),
@TrueNumFields int,
@TrueTotalSize int
AS
Declare
  @TableId int,
  @NumFields int,
  @TotalSize int,
  @Msg varchar(1000)
SELECT @Tblname = 'dbo.' + @Tblname
Select @TableId = NULL
Select @TableId = object_id(@Tblname) 
If (@TableId Is NULL)
  Begin
    Select @Msg = '-- Warning: Missing Table [' + @Tblname + ']'
    Print @Msg
    Return
  End
Select @NumFields = 0
Select @TotalSize = 0
Select @NumFields = Count(Name) From sys.syscolumns Where Id = @TableId
Select @TotalSize = Sum(Length) From sys.syscolumns Where Id = @TableId
If (@NumFields < @TrueNumFields)
  Begin
    Select @Msg = '-- Warning: Mismatch on Number of Columns [' + @Tblname + '] Should Be [' + Convert(varchar(10),@TrueNumFields) + '] Not [' + Convert(varchar(10),@NumFields) + ']'
    Print @Msg
  End
--If (@TotalSize <> @TrueTotalSize)
--  Begin
--    Select @Msg = '-- Warning: Mismatch on Total Table Size  [' + @Tblname + '] Should Be [' + Convert(varchar(10),@TrueTotalSize) + '] Not [' + Convert(varchar(10),@TotalSize) + ']'
--    Print @Msg
--  End
