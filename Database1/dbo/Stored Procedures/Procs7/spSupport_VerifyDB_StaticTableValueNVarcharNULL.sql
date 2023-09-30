CREATE procedure dbo.spSupport_VerifyDB_StaticTableValueNVarcharNULL
@TblName varchar(100),
@IdFieldName varchar(100),
@DescFieldName varchar(100),
@TheId int,
@TheDesc nvarchar(2000),
@ForceCompare int = 1,
@ExtraColName1 nvarchar(100) = NULL,
@ExtraColVal1 nvarchar(2000) = NULL,
@ForceExtraCompare1 int = 0,
@ExtraColName2 nvarchar(100) = NULL,
@ExtraColVal2 nvarchar(2000) = NULL,
@ForceExtraCompare2 int = 0,
@KeyCount 	  	 Int = 1
AS
Declare
  @Statement nvarchar(4000),
  @StatementBEGIN nvarchar(4000),
  @StatementMIDDLE1 nvarchar(4000),
  @StatementMIDDLE2 nvarchar(4000),
  @StatementEND nvarchar(4000),
  @StatementVal1 nvarchar(2000),
  @StatementVal2 nvarchar(255),
  @ActualId int,
  @ActualDesc nvarchar(2000),
  @Msg varchar(5000),
  @HasIdentity int,
  @TableId int,
  @ActualExtraVal1 nvarchar(1000),
  @ActualExtraVal2 nvarchar(1000),
  @DoIt bit,
  @WhereClause 	  	 VarChar(1000)
Select @KeyCount = isnull(@KeyCount,1)
If (@ExtraColName1 Is NULL) Select @ExtraColName1 = ''
If (@ExtraColName2 Is NULL) Select @ExtraColName2 = ''
If @TheDesc = '{NULL}' Select @TheDesc = 'NULL' 
If @ExtraColVal1 = '{NULL}' Select @StatementVal1 = 'NULL' Else Select @StatementVal1 = 'N''' + @ExtraColVal1 + '''' 
If @ExtraColVal2 = '{NULL}' Select @StatementVal2 = 'NULL' Else Select @StatementVal2 = 'N''' + @ExtraColVal2 + '''' 
If @KeyCount = 1
 	 Select @WhereClause = ' Where (' + @IdFieldName + ' = ' + Convert(varchar(10),@TheId) + ')'
Else If @KeyCount = 2
 	 Select @WhereClause = ' Where (' + @IdFieldName + ' = ' + Convert(varchar(10),@TheId) + ') And (' + @DescFieldName + ' = ' + Convert(varchar(10),@TheDesc) + ')'
Else If @KeyCount = 3
    Select @WhereClause = ' Where (' + @IdFieldName + ' = ' + Convert(varchar(10),@TheId) + ') And (' + @DescFieldName + ' = ' + Convert(varchar(10),@TheDesc) + ') And (' + @ExtraColName1 + ' = ' + Convert(varchar(10),@ExtraColVal1) + ')'
DECLARE @dboTblname VarChar(110) 
SELECT @dboTblname = 'dbo.' + @Tblname
Select @TableId = NULL
Select @TableId = object_id(@dboTblname) 
If (@TableId Is NULL)
  Begin
    Return
  End
Create Table #TmpStaticInfo (
  TheId int NULL, 
  TheDesc nvarchar(2000) NULL, 
  ExtraVal1 nvarchar(1000) NULL, 
  ExtraVal2 nvarchar(1000) NULL
  )
Select @StatementBEGIN = 'Insert Into #TmpStaticInfo (TheId,TheDesc'
Select @StatementMIDDLE1 = ') Select ' + @IdFieldName + ',' + @DescFieldName  
Select @StatementEND = ' From ' + @dboTblname + @WhereClause
If (@ExtraColName1 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal1', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName1
If (@ExtraColName2 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal2', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName2 
Execute (@StatementBEGIN + @StatementMIDDLE1 + @StatementEND)
Select @ActualId = NULL
Select @ActualId = TheId, @ActualDesc = TheDesc, 
                     @ActualExtraVal1 = 'N''' + ExtraVal1 + '''', 
                     @ActualExtraVal2 = 'N''' + ExtraVal2 + ''''
 	 From #TmpStaticInfo
Drop Table #TmpStaticInfo  
If (@ActualId Is NULL)
  Begin
    Select @HasIdentity = NULL
    Select @HasIdentity = a.Id
      From sys.syscolumns a
      Join sys.sysobjects b on b.Id = a.Id
      Where (b.Type = 'U') And ((a.Status & Power(2,7)) != 0) AND (b.Name = @Tblname)
    Select @StatementBEGIN = ''
    Select @StatementEND = ''
    Select @StatementBEGIN = @StatementBEGIN + 'Insert Into ' + @dboTblname + '(' + @IdFieldName + ',' + @DescFieldName 
    Select @StatementMIDDLE2 = + ') Values(' + Convert(varchar(10),@TheId) + ',N''' + COALESCE(@TheDesc, '') + ''''
    Select @StatementMIDDLE1 = ''
    Select @StatementEND = ')' + @StatementEND
    If (@ExtraColName1 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName1, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal1 
    If (@ExtraColName2 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName2, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal2 
    Select @Statement = ''
    If (@HasIdentity Is Not NULL) And (@KeyCount = 1) Select @Statement = 'Set Identity_Insert ' + @dboTblname + ' On '
    Select @Statement = @Statement + @StatementBEGIN + @StatementMIDDLE1 + @StatementMIDDLE2 + @StatementEND
    If (@HasIdentity Is Not NULL)  And (@KeyCount = 1) Select @Statement = @Statement + ' Set Identity_Insert ' + @dboTblname + ' Off'
    Execute (@Statement)
    Select @Msg = '-- Added [' + @TheDesc + '] To Static Table [' + @dboTblname + ']'
    Print @Msg
    Return
  End
If (@ActualDesc <> @TheDesc) And (@ForceCompare = 1)
  Begin
    Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @DescFieldName + ' = N''' + @TheDesc  + '''' + @WhereClause
    Execute (@StatementMIDDLE1)
    Select @Msg = '-- Updated Static Table Column [' + @DescFieldName + '] For [' + @dboTblname + ']'
    Print @Msg
  End
If (@ForceExtraCompare1 = 1)
  If (@ActualExtraVal1 IS NULL and @StatementVal1 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal1 IS NULL and @StatementVal1 IS NOT NULL) OR (@ActualExtraVal1 IS NOT NULL and @StatementVal1 IS NULL) OR (@ActualExtraVal1 <> @StatementVal1) OR (@ActualExtraVal1 = 'Null' and @StatementVal1= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName1 + ' = ' + @StatementVal1   + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName1 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare2 = 1) 
  If (@ActualExtraVal2 IS NULL and @StatementVal2 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal2 IS NULL and @StatementVal2 IS NOT NULL) OR (@ActualExtraVal2 IS NOT NULL and @StatementVal2 IS NULL) OR (@ActualExtraVal2 <> @StatementVal2) OR (@ActualExtraVal2 = 'Null' and @StatementVal2= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName2 +  ' = ' + @StatementVal2   + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName2 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
