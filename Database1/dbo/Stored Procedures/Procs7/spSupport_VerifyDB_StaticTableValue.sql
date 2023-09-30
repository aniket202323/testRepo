create procedure dbo.spSupport_VerifyDB_StaticTableValue
@TblName varchar(100),
@IdFieldName varchar(100),
@DescFieldName varchar(100),
@TheId int,
@TheDesc varchar(100),
@ForceCompare int = 1,
@ExtraColName1 varchar(100) = NULL,
@ExtraColVal1 varchar(100) = NULL,
@ForceExtraCompare1 int = 0,
@ExtraColName2 varchar(100) = NULL,
@ExtraColVal2 varchar(100) = NULL,
@ForceExtraCompare2 int = 0
AS
Declare
  @Statement varchar(255),
  @ActualId int,
  @ActualDesc varchar(100),
  @Msg varchar(255),
  @HasIdentity int,
  @TableId int,
  @ActualExtraVal1 varchar(100),
  @ActualExtraVal2 varchar(100)
If (@ExtraColName1 Is NULL)
  Select @ExtraColName1 = ''
If (@ExtraColName2 Is NULL)
  Select @ExtraColName2 = ''
SELECT @Tblname = 'dbo.' + @Tblname
Select @TableId = NULL
Select @TableId = object_id(@Tblname)
If (@TableId Is NULL)
  Begin
    Return
  End
Create Table #TmpStaticInfo (TheId int NULL, TheDesc varchar(100) NULL, ExtraVal1 varchar(100) NULL, ExtraVal2 varchar(100) NULL)
If (@ExtraColName1 = '')
  Select @Statement = 'Insert Into #TmpStaticInfo (TheId,TheDesc) (Select ' + @IdFieldName + ',' + @DescFieldName + ' From ' + @Tblname + ' Where (' + @IdFieldName + ' = ' + Convert(varchar(10),@TheId) + '))'
Else
  If (@ExtraColName2 = '')
    Select @Statement = 'Insert Into #TmpStaticInfo (TheId,TheDesc,ExtraVal1) (Select ' + @IdFieldName + ',' + @DescFieldName + ',' + @ExtraColName1 + ' From ' + @Tblname + ' Where (' + @IdFieldName + ' = ' + Convert(varchar(10),@TheId) + '))'
  Else
    Select @Statement = 'Insert Into #TmpStaticInfo (TheId,TheDesc,ExtraVal1,ExtraVal2) (Select ' + @IdFieldName + ',' + @DescFieldName + ',' + @ExtraColName1 + ',' + @ExtraColName2 + ' From ' + @Tblname + ' Where (' + @IdFieldName + ' = ' + Convert(varchar(10),@TheId) + '))'
Execute (@Statement)
Select @ActualId = NULL
Select @ActualId = TheId, @ActualDesc = TheDesc, @ActualExtraVal1 = ExtraVal1, @ActualExtraVal2 = ExtraVal2 From #TmpStaticInfo
Drop Table #TmpStaticInfo  
If (@ActualId Is NULL)
  Begin
    Select @HasIdentity = NULL
    Select @HasIdentity = a.Id
      From sys.syscolumns a
      Join sys.sysobjects b on b.Id = a.Id
      Where (b.Type = 'U') And ((a.Status & Power(2,7)) != 0) AND (b.Name = @Tblname)
    If (@HasIdentity Is NULL)
      Begin
 	 If (@ExtraColName1 = '')     
          Select @Statement = 'Insert Into ' + @Tblname + '(' + @IdFieldName + ',' + @DescFieldName + ') Values(' + Convert(varchar(10),@TheId) + ',''' + @TheDesc + ''')'
        Else
 	   If (@ExtraColName2 = '')     
            Select @Statement = 'Insert Into ' + @Tblname + '(' + @IdFieldName + ',' + @DescFieldName + ',' + @ExtraColName1 + ') Values(' + Convert(varchar(10),@TheId) + ',''' + @TheDesc + ''',''' + @ExtraColVal1 + ''')'
          Else
            Select @Statement = 'Insert Into ' + @Tblname + '(' + @IdFieldName + ',' + @DescFieldName + ',' + @ExtraColName1 + ',' + @ExtraColName2 + ') Values(' + Convert(varchar(10),@TheId) + ',''' + @TheDesc + ''',''' + @ExtraColVal1 + ''',''' + @ExtraColVal2 + ''')'
        Execute (@Statement)
      End
    Else
      Begin
 	 If (@ExtraColName1 = '')     
          Select @Statement = 'Set Identity_Insert ' + @Tblname + ' On' + ' Insert Into ' + @Tblname + '(' + @IdFieldName + ',' + @DescFieldName + ') Values(' + Convert(varchar(10),@TheId) + ',''' + @TheDesc + ''')' + ' Set Identity_Insert ' + @Tblname + ' Off'
        Else
 	   If (@ExtraColName2 = '')     
            Select @Statement = 'Set Identity_Insert ' + @Tblname + ' On' + ' Insert Into ' + @Tblname + '(' + @IdFieldName + ',' + @DescFieldName + ',' + @ExtraColName1 + ') Values(' + Convert(varchar(10),@TheId) + ',''' + @TheDesc + ''',''' + @ExtraColVal1 + ''') Set Identity_Insert ' + @Tblname + ' Off'
          Else
            Select @Statement = 'Set Identity_Insert ' + @Tblname + ' On' + ' Insert Into ' + @Tblname + '(' + @IdFieldName + ',' + @DescFieldName + ',' + @ExtraColName1 + ',' + @ExtraColName2 + ') Values(' + Convert(varchar(10),@TheId) + ',''' + @TheDesc + ''',''' + @ExtraColVal1 + ''',''' + @ExtraColVal2 + ''') Set Identity_Insert ' + @Tblname + ' Off'
        Execute (@Statement)
      End
    Select @Msg = '-- Added [' + @TheDesc + '] To Static Table [' + @Tblname + ']'
    Print @Msg
    Return
  End
If (@ActualDesc <> @TheDesc) And (@ForceCompare = 1)
  Begin
    Select @Statement = 'Update ' + @Tblname + ' Set ' + @DescFieldName + ' = ''' + @TheDesc + ''' Where (' + @IdFieldName + ' = ' + Convert(varchar(10),@TheId) + ')' 
    Execute (@Statement)
    Select @Msg = '-- Updated Static Table Column [' + @DescFieldName + '] For [' + @Tblname + ']'
    Print @Msg
  End
If (@ForceExtraCompare1 = 1)
  If (@ActualExtraVal1 <> @ExtraColVal1) Or (@ActualExtraVal1 Is NULL)
    Begin
      Select @Statement = 'Update ' + @Tblname + ' Set ' + @ExtraColName1 + ' = ''' + @ExtraColVal1 + ''' Where (' + @IdFieldName + ' = ' + Convert(varchar(10),@TheId) + ')' 
      Execute (@Statement)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName1 + '] For [' + @Tblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare2 = 1)
  If (@ActualExtraVal2 <> @ExtraColVal2) Or (@ActualExtraVal2 Is NULL)
    Begin
      Select @Statement = 'Update ' + @Tblname + ' Set ' + @ExtraColName2 + ' = ''' + @ExtraColVal2 + ''' Where (' + @IdFieldName + ' = ' + Convert(varchar(10),@TheId) + ')' 
      Execute (@Statement)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName2 + '] For [' + @Tblname + ']'
      Print @Msg      
    End
