create procedure dbo.spSupport_VerifyDB_StaticTableValueNULL
@KeyColumns int,
@TblName varchar(100),
@IdFieldName varchar(100),
@DescFieldName varchar(100),
@TheId int,
@TheDesc varchar(2000),
@ForceCompare int = 1,
@ExtraColName1 varchar(100) = NULL,
@ExtraColVal1 varchar(2000) = NULL,
@ForceExtraCompare1 int = 0,
@ExtraColName2 varchar(100) = NULL,
@ExtraColVal2 varchar(500) = NULL,
@ForceExtraCompare2 int = 0,
@ExtraColName3 varchar(100) = NULL,
@ExtraColVal3 varchar(500) = NULL,
@ForceExtraCompare3 int = 0,
@ExtraColName4 varchar(100) = NULL,
@ExtraColVal4 varchar(500) = NULL,
@ForceExtraCompare4 int = 0,
@ExtraColName5 varchar(100) = NULL,
@ExtraColVal5 varchar(500) = NULL,
@ForceExtraCompare5 int = 0,
@ExtraColName6 varchar(100) = NULL,
@ExtraColVal6 varchar(100) = NULL,
@ForceExtraCompare6 int = 0,
@ExtraColName7 varchar(100) = NULL,
@ExtraColVal7 varchar(100) = NULL,
@ForceExtraCompare7 int = 0,
@ExtraColName8 varchar(100) = NULL,
@ExtraColVal8 varchar(100) = NULL,
@ForceExtraCompare8 int = 0,
@ExtraColName9 varchar(100) = NULL,
@ExtraColVal9 varchar(100) = NULL,
@ForceExtraCompare9 int = 0,
@ExtraColName10 varchar(100) = NULL,
@ExtraColVal10 varchar(100) = NULL,
@ForceExtraCompare10 int = 0,
@ExtraColName11 varchar(100) = NULL,
@ExtraColVal11 varchar(100) = NULL,
@ForceExtraCompare11 int = 0,
@ExtraColName12 varchar(100) = NULL,
@ExtraColVal12 varchar(100) = NULL,
@ForceExtraCompare12 int = 0,
@ExtraColName13 varchar(100) = NULL,
@ExtraColVal13 varchar(100) = NULL,
@ForceExtraCompare13 int = 0,
@ExtraColName14 varchar(100) = NULL,
@ExtraColVal14 varchar(100) = NULL,
@ForceExtraCompare14 int = 0,
@ExtraColName15 varchar(100) = NULL,
@ExtraColVal15 varchar(100) = NULL,
@ForceExtraCompare15 int = 0,
@ExtraColName16 varchar(100) = NULL,
@ExtraColVal16 varchar(100) = NULL,
@ForceExtraCompare16 int = 0,
@ExtraColName17 varchar(100) = NULL,
@ExtraColVal17 varchar(100) = NULL,
@ForceExtraCompare17 int = 0,
@ExtraColName18 varchar(100) = NULL,
@ExtraColVal18 varchar(100) = NULL,
@ForceExtraCompare18 int = 0
AS
Declare
  @Statement varchar(5000),
  @StatementBEGIN varchar(5000),
  @StatementMIDDLE1 varchar(5000),
  @StatementMIDDLE2 varchar(5000),
  @StatementEND varchar(5000),
  @StatementVal1 varchar(2000),
  @StatementVal2 varchar(600),
  @StatementVal3 varchar(600),
  @StatementVal4 varchar(600),
  @StatementVal5 varchar(600),
  @StatementVal6 varchar(255),
  @StatementVal7 varchar(255),
  @StatementVal8 varchar(255),
  @StatementVal9 varchar(255),
  @StatementVal10 varchar(255),
  @StatementVal11 varchar(255),
  @StatementVal12 varchar(255),
  @StatementVal13 varchar(255),
  @StatementVal14 varchar(255),
  @StatementVal15 varchar(255),
  @StatementVal16 varchar(255),
  @StatementVal17 varchar(255),
  @StatementVal18 varchar(255),
  @ActualId int,
  @ActualDesc varchar(2000),
  @Msg varchar(5000),
  @HasIdentity int,
  @TableId int,
  @ActualExtraVal1 varchar(2000),
  @ActualExtraVal2 varchar(500),
  @ActualExtraVal3 varchar(500),
  @ActualExtraVal4 varchar(500),
  @ActualExtraVal5 varchar(500),
  @ActualExtraVal6 varchar(100),
  @ActualExtraVal7 varchar(100),
  @ActualExtraVal8 varchar(100), 
  @ActualExtraVal9 varchar(100), 
  @ActualExtraVal10 varchar(100), 
  @ActualExtraVal11 varchar(100), 
  @ActualExtraVal12 varchar(100), 
  @ActualExtraVal13 varchar(100), 
  @ActualExtraVal14 varchar(100), 
  @ActualExtraVal15 varchar(100), 
  @ActualExtraVal16 varchar(100), 
  @ActualExtraVal17 varchar(100), 
  @ActualExtraVal18 varchar(100), 
  @DoIt bit,
  @WhereClause 	  	 VarChar(1000)
If (@ExtraColName1 Is NULL) Select @ExtraColName1 = ''
If (@ExtraColName2 Is NULL) Select @ExtraColName2 = ''
If (@ExtraColName3 Is NULL) Select @ExtraColName3 = ''
If (@ExtraColName4 Is NULL) Select @ExtraColName4 = ''
If (@ExtraColName5 Is NULL) Select @ExtraColName5 = ''
If (@ExtraColName6 Is NULL) Select @ExtraColName6 = ''
If (@ExtraColName7 Is NULL) Select @ExtraColName7 = ''
If (@ExtraColName8 Is NULL) Select @ExtraColName8 = ''
If (@ExtraColName9 Is NULL) Select @ExtraColName9 = ''
If (@ExtraColName10 Is NULL) Select @ExtraColName10= ''
If (@ExtraColName11 Is NULL) Select @ExtraColName11= ''
If (@ExtraColName12 Is NULL) Select @ExtraColName12= ''
If (@ExtraColName13 Is NULL) Select @ExtraColName13= ''
If (@ExtraColName14 Is NULL) Select @ExtraColName14= ''
If (@ExtraColName15 Is NULL) Select @ExtraColName15= ''
If (@ExtraColName16 Is NULL) Select @ExtraColName16= ''
If (@ExtraColName17 Is NULL) Select @ExtraColName17= ''
If (@ExtraColName18 Is NULL) Select @ExtraColName18= ''
If @TheDesc = '{NULL}' Select @TheDesc = 'NULL' 
If @ExtraColVal1 = '{NULL}' Select @StatementVal1 = 'NULL' Else Select @StatementVal1 = '''' + @ExtraColVal1 + '''' 
If @ExtraColVal2 = '{NULL}' Select @StatementVal2 = 'NULL' Else Select @StatementVal2 = '''' + @ExtraColVal2 + '''' 
If @ExtraColVal3 = '{NULL}' Select @StatementVal3 = 'NULL' Else Select @StatementVal3 = '''' + @ExtraColVal3 + '''' 
If @ExtraColVal4 = '{NULL}' Select @StatementVal4 = 'NULL' Else Select @StatementVal4 = '''' + @ExtraColVal4 + '''' 
If @ExtraColVal5 = '{NULL}' Select @StatementVal5 = 'NULL' Else Select @StatementVal5 = '''' + @ExtraColVal5 + '''' 
If @ExtraColVal6 = '{NULL}' Select @StatementVal6 = 'NULL' Else Select @StatementVal6 = '''' + @ExtraColVal6 + '''' 
If @ExtraColVal7 = '{NULL}' Select @StatementVal7 = 'NULL' Else Select @StatementVal7 = '''' + @ExtraColVal7 + '''' 
If @ExtraColVal8 = '{NULL}' Select @StatementVal8 = 'NULL' Else Select @StatementVal8 = '''' + @ExtraColVal8 + '''' 
If @ExtraColVal9 = '{NULL}' Select @StatementVal9 = 'NULL' Else Select @StatementVal9 = '''' + @ExtraColVal9 + '''' 
If @ExtraColVal10 = '{NULL}' Select @StatementVal10 = 'NULL' Else Select @StatementVal10 = '''' + @ExtraColVal10 + '''' 
If @ExtraColVal11 = '{NULL}' Select @StatementVal11 = 'NULL' Else Select @StatementVal11 = '''' + @ExtraColVal11 + '''' 
If @ExtraColVal12 = '{NULL}' Select @StatementVal12 = 'NULL' Else Select @StatementVal12 = '''' + @ExtraColVal12 + '''' 
If @ExtraColVal13 = '{NULL}' Select @StatementVal13 = 'NULL' Else Select @StatementVal13 = '''' + @ExtraColVal13 + '''' 
If @ExtraColVal14 = '{NULL}' Select @StatementVal14 = 'NULL' Else Select @StatementVal14 = '''' + @ExtraColVal14 + '''' 
If @ExtraColVal15 = '{NULL}' Select @StatementVal15 = 'NULL' Else Select @StatementVal15 = '''' + @ExtraColVal15 + '''' 
If @ExtraColVal16 = '{NULL}' Select @StatementVal16 = 'NULL' Else Select @StatementVal16 = '''' + @ExtraColVal16 + '''' 
If @ExtraColVal17 = '{NULL}' Select @StatementVal17 = 'NULL' Else Select @StatementVal17 = '''' + @ExtraColVal17 + '''' 
If @ExtraColVal18 = '{NULL}' Select @StatementVal18 = 'NULL' Else Select @StatementVal18 = '''' + @ExtraColVal18 + '''' 
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
  TheDesc varchar(2000) NULL, 
  ExtraVal1 varchar(2000) NULL, 
  ExtraVal2 varchar(500) NULL, 
  ExtraVal3 varchar(500) NULL, 
  ExtraVal4 varchar(500) NULL, 
  ExtraVal5 varchar(500) NULL, 
  ExtraVal6 varchar(100) NULL, 
  ExtraVal7 varchar(100) NULL, 
  ExtraVal8 varchar(100) NULL,
  ExtraVal9 varchar(100) NULL,
  ExtraVal10 varchar(100) NULL,
  ExtraVal11 varchar(100) NULL,
  ExtraVal12 varchar(100) NULL,
  ExtraVal13 varchar(100) NULL,
  ExtraVal14 varchar(100) NULL,
  ExtraVal15 varchar(100) NULL,
  ExtraVal16 varchar(100) NULL,
  ExtraVal17 varchar(100) NULL,
  ExtraVal18 varchar(100) NULL
  )
Declare  @IsCalculated 	 Int,
   	  	 @ObjectId 	  	 Int
Select @ObjectId = id From sys.Sysobjects where name = @TblName and xtype = 'U'
Select @IsCalculated = iscomputed From sys.syscolumns where Name = @DescFieldName and id = @ObjectId
Select @IsCalculated = isnull(@IsCalculated,0)
If @IsCalculated = 1
 	 Select @DescFieldName = @DescFieldName +  '_local'
If @KeyColumns = 1
 	 Select @WhereClause = ' Where (' + @IdFieldName + ' = ''' + Convert(varchar(100),@TheId) + ''')'
ELSE IF @KeyColumns = 2
 	 Select @WhereClause = ' Where (' + @IdFieldName + ' = ''' + Convert(varchar(100),@TheId) + ''') And (' + @DescFieldName + ' = ''' + Convert(varchar(100),@TheDesc) + ''')'
ELSE IF @KeyColumns = 3
 	 Select @WhereClause = ' Where (' + @IdFieldName + ' = ''' + Convert(varchar(100),@TheId) + ''') And (' + @DescFieldName + ' = ''' + Convert(varchar(100),@TheDesc) + ''') And (' + @ExtraColName1 + ' = ''' + Convert(varchar(100),@ExtraColVal1) + ''')'
Select @StatementBEGIN = 'Insert Into #TmpStaticInfo (TheId,TheDesc'
Select @StatementMIDDLE1 = ') Select ' + @IdFieldName + ',' + @DescFieldName  
Select @StatementEND = ' From ' + @dboTblname + @WhereClause
If (@ExtraColName1 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal1', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName1
If (@ExtraColName2 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal2', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName2 
If (@ExtraColName3 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal3', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName3 
If (@ExtraColName4 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal4', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName4 
If (@ExtraColName5 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal5', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName5 
If (@ExtraColName6 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal6', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName6 
If (@ExtraColName7 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal7', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName7 
If (@ExtraColName8 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal8', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName8 
If (@ExtraColName9 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal9', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName9 
If (@ExtraColName10 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal10', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName10
If (@ExtraColName11 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal11', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName11
If (@ExtraColName12 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal12', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName12
If (@ExtraColName13 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal13', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName13
If (@ExtraColName14 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal14', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName14
If (@ExtraColName15 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal15', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName15
If (@ExtraColName16 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal16', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName15
If (@ExtraColName17 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal17', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName15
If (@ExtraColName18 <> '') Select @StatementBEGIN = @StatementBEGIN + ',ExtraVal18', @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName15
Execute (@StatementBEGIN + @StatementMIDDLE1 + @StatementEND)
Select @ActualId = NULL
Select @ActualId = TheId, @ActualDesc = TheDesc, 
                     @ActualExtraVal1 = '''' + ExtraVal1 + '''', 
                     @ActualExtraVal2 = '''' + ExtraVal2 + '''', 
                     @ActualExtraVal3 = '''' + ExtraVal3 + '''', 
                     @ActualExtraVal4 = '''' + ExtraVal4 + '''', 
                     @ActualExtraVal5 = '''' + ExtraVal5 + '''', 
                     @ActualExtraVal6 = '''' + ExtraVal6 + '''', 
                     @ActualExtraVal7 = '''' + ExtraVal7 + '''', 
                     @ActualExtraVal8 = '''' + ExtraVal8 + '''', 
                     @ActualExtraVal9 = '''' + ExtraVal9 + '''', 
                     @ActualExtraVal10 = '''' + ExtraVal10 + '''', 
                     @ActualExtraVal11 = '''' + ExtraVal11 + '''', 
                     @ActualExtraVal12 = '''' + ExtraVal12 + '''', 
                     @ActualExtraVal13 = '''' + ExtraVal13 + '''', 
                     @ActualExtraVal14 = '''' + ExtraVal14 + '''', 
                     @ActualExtraVal15 = '''' + ExtraVal15 + '''',
                     @ActualExtraVal16 = '''' + ExtraVal16 + '''',
                     @ActualExtraVal17 = '''' + ExtraVal17 + '''',
                     @ActualExtraVal18 = '''' + ExtraVal18 + '''' 
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
    Select @StatementMIDDLE2 = + ') Values(' + Convert(varchar(100),@TheId) + ',''' + COALESCE(@TheDesc, '') + ''''
    Select @StatementMIDDLE1 = ''
    Select @StatementEND = ')' + @StatementEND
    If (@ExtraColName1 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName1, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal1 
    If (@ExtraColName2 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName2, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal2 
    If (@ExtraColName3 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName3, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal3 
    If (@ExtraColName4 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName4, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal4 
    If (@ExtraColName5 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName5, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal5 
    If (@ExtraColName6 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName6, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal6 
    If (@ExtraColName7 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName7, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal7 
    If (@ExtraColName8 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName8, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal8 
    If (@ExtraColName9 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName9, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal9 
    If (@ExtraColName10 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName10, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal10 
    If (@ExtraColName11 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName11, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal11 
    If (@ExtraColName12 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName12, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal12 
    If (@ExtraColName13 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName13, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal13 
    If (@ExtraColName14 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName14, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal14 
    If (@ExtraColName15 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName15, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal15 
    If (@ExtraColName16 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName16, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal16 
    If (@ExtraColName17 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName17, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal17 
    If (@ExtraColName18 <> '') Select @StatementMIDDLE1 = @StatementMIDDLE1 + ',' + @ExtraColName18, @StatementMIDDLE2 = @StatementMIDDLE2 + ', ' + @StatementVal18 
    Select @Statement = ''
    If (@HasIdentity Is Not NULL) Select @Statement = 'Set Identity_Insert ' + @dboTblname + ' On '
    Select @Statement = @Statement + @StatementBEGIN + @StatementMIDDLE1 + @StatementMIDDLE2 + @StatementEND
    If (@HasIdentity Is Not NULL) Select @Statement = @Statement + ' Set Identity_Insert ' + @dboTblname + ' Off'
    Execute (@Statement)
    Select @Msg = '-- Added [' + @TheDesc + '] To Static Table [' + @dboTblname + ']'
    Print @Msg
    Return
  End
If (@ActualDesc <> @TheDesc) And (@ForceCompare = 1)
  Begin
    Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @DescFieldName + ' = ''' + @TheDesc + '''' + @WhereClause
    Execute (@StatementMIDDLE1)
    Select @Msg = '-- Updated Static Table Column [' + @DescFieldName + '] For [' + @dboTblname + ']'
    Print @Msg
  End
If (@ForceExtraCompare1 = 1)
  If (@ActualExtraVal1 IS NULL and @StatementVal1 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal1 IS NULL and @StatementVal1 IS NOT NULL) OR (@ActualExtraVal1 IS NOT NULL and @StatementVal1 IS NULL) OR (@ActualExtraVal1 <> @StatementVal1) OR (@ActualExtraVal1 = 'Null' and @StatementVal1= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName1 + ' = ' + @StatementVal1  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName1 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare2 = 1) 
  If (@ActualExtraVal2 IS NULL and @StatementVal2 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal2 IS NULL and @StatementVal2 IS NOT NULL) OR (@ActualExtraVal2 IS NOT NULL and @StatementVal2 IS NULL) OR (@ActualExtraVal2 <> @StatementVal2) OR (@ActualExtraVal2 = 'Null' and @StatementVal2= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName2 + ' = ' + @StatementVal2  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName2 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare3 = 1)
  If (@ActualExtraVal3 IS NULL and @StatementVal3 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal3 IS NULL and @StatementVal3 IS NOT NULL) OR (@ActualExtraVal3 IS NOT NULL and @StatementVal3 IS NULL) OR (@ActualExtraVal3 <> @StatementVal3) OR (@ActualExtraVal3 = 'Null' and @StatementVal3= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName3 + ' = ' + @StatementVal3  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName3 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare4 = 1)
  If (@ActualExtraVal4 IS NULL and @StatementVal4 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal4 IS NULL and @StatementVal4 IS NOT NULL) OR (@ActualExtraVal4 IS NOT NULL and @StatementVal4 IS NULL) OR (@ActualExtraVal4 <> @StatementVal4) OR (@ActualExtraVal4 = 'Null' and @StatementVal4= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName4 + ' = ' + @StatementVal4  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName4 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare5 = 1)
  If (@ActualExtraVal5 IS NULL and @StatementVal5 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal5 IS NULL and @StatementVal5 IS NOT NULL) OR (@ActualExtraVal5 IS NOT NULL and @StatementVal5 IS NULL) OR (@ActualExtraVal5 <> @StatementVal5) OR (@ActualExtraVal5 = 'Null' and @StatementVal5= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName5 + ' = ' + @StatementVal5  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName5 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare6 = 1)
  If (@ActualExtraVal6 IS NULL and @StatementVal6 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal6 IS NULL and @StatementVal6 IS NOT NULL) OR (@ActualExtraVal6 IS NOT NULL and @StatementVal6 IS NULL) OR (@ActualExtraVal6 <> @StatementVal6) OR (@ActualExtraVal6 = 'Null' and @StatementVal6= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName6 + ' = ' + @StatementVal6  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName6 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare7 = 1)
  If (@ActualExtraVal7 IS NULL and @StatementVal7 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal7 IS NULL and @StatementVal7 IS NOT NULL) OR (@ActualExtraVal7 IS NOT NULL and @StatementVal7 IS NULL) OR (@ActualExtraVal7 <> @StatementVal7) OR (@ActualExtraVal7 = 'Null' and @StatementVal7= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName7 + ' = ' + @StatementVal7  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName7 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare8 = 1)
  If (@ActualExtraVal8 IS NULL and @StatementVal8 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal8 IS NULL and @StatementVal8 IS NOT NULL) OR (@ActualExtraVal8 IS NOT NULL and @StatementVal8 IS NULL) OR (@ActualExtraVal8 <> @StatementVal8) OR (@ActualExtraVal8 = 'Null' and @StatementVal8= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName8 + ' = ' + @StatementVal8  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName8 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare9 = 1)
  If (@ActualExtraVal9 IS NULL and @StatementVal9 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal9 IS NULL and @StatementVal9 IS NOT NULL) OR (@ActualExtraVal9 IS NOT NULL and @StatementVal9 IS NULL) OR (@ActualExtraVal9 <> @StatementVal9) OR (@ActualExtraVal9 = 'Null' and @StatementVal9= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName9 + ' = ' + @StatementVal9  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName9 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare10 = 1)
  If (@ActualExtraVal10 IS NULL and @StatementVal10 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal10 IS NULL and @StatementVal10 IS NOT NULL) OR (@ActualExtraVal10 IS NOT NULL and @StatementVal10 IS NULL) OR (@ActualExtraVal10 <> @StatementVal10) OR (@ActualExtraVal10 = 'Null' and @StatementVal10= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName10 + ' = ' + @StatementVal10  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName10 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare11 = 1)
  If (@ActualExtraVal11 IS NULL and @StatementVal11 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal11 IS NULL and @StatementVal11 IS NOT NULL) OR (@ActualExtraVal11 IS NOT NULL and @StatementVal11 IS NULL) OR (@ActualExtraVal11 <> @StatementVal11) OR (@ActualExtraVal11 = 'Null' and @StatementVal11= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName11 + ' = ' + @StatementVal11  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName11 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare12 = 1)
  If (@ActualExtraVal12 IS NULL and @StatementVal12 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal12 IS NULL and @StatementVal12 IS NOT NULL) OR (@ActualExtraVal12 IS NOT NULL and @StatementVal12 IS NULL) OR (@ActualExtraVal12 <> @StatementVal12) OR (@ActualExtraVal12 = 'Null' and @StatementVal12= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName12 + ' = ' + @StatementVal12  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName12 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare13 = 1)
  If (@ActualExtraVal13 IS NULL and @StatementVal13 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal13 IS NULL and @StatementVal13 IS NOT NULL) OR (@ActualExtraVal13 IS NOT NULL and @StatementVal13 IS NULL) OR (@ActualExtraVal13 <> @StatementVal13) OR (@ActualExtraVal13 = 'Null' and @StatementVal13= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName13 + ' = ' + @StatementVal13  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName13 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare14 = 1)
  If (@ActualExtraVal14 IS NULL and @StatementVal14 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal14 IS NULL and @StatementVal14 IS NOT NULL) OR (@ActualExtraVal14 IS NOT NULL and @StatementVal14 IS NULL) OR (@ActualExtraVal14 <> @StatementVal14) OR (@ActualExtraVal14 = 'Null' and @StatementVal14= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName14 + ' = ' + @StatementVal14  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName14 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare15 = 1)
  If (@ActualExtraVal15 IS NULL and @StatementVal15 = 'Null')
    Select @Msg = ''
  Else If ((@ActualExtraVal15 IS NULL and @StatementVal15 IS NOT NULL) OR (@ActualExtraVal15 IS NOT NULL and @StatementVal15 IS NULL) OR (@ActualExtraVal15 <> @StatementVal15) OR (@ActualExtraVal15 = 'Null' and @StatementVal15= 'Null'))
    Begin
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName15 + ' = ' + @StatementVal15  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName15 + '] For [' + @dboTblname + ']'
      Print @Msg      
    End
If (@ForceExtraCompare16 = 1)
BEGIN
 	 If (@ActualExtraVal16 IS NULL and @StatementVal16 = 'Null')
 	 BEGIN
 	  	 Select @Msg = ''
 	 END
 	 ELSE IF ((@ActualExtraVal16 IS NULL and @StatementVal16 IS NOT NULL) OR (@ActualExtraVal16 IS NOT NULL and @StatementVal16 IS NULL) OR (@ActualExtraVal16 <> @StatementVal16) OR (@ActualExtraVal16 = 'Null' and @StatementVal16= 'Null'))
    BEGIN
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName16 + ' = ' + @StatementVal16  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName16 + '] For [' + @dboTblname + ']'
      Print @Msg      
    END
END
If (@ForceExtraCompare17 = 1)
BEGIN
 	 If (@ActualExtraVal17 IS NULL and @StatementVal17 = 'Null')
 	 BEGIN
 	  	 Select @Msg = ''
 	 END
 	 ELSE IF ((@ActualExtraVal17 IS NULL and @StatementVal17 IS NOT NULL) OR (@ActualExtraVal17 IS NOT NULL and @StatementVal17 IS NULL) OR (@ActualExtraVal17 <> @StatementVal17) OR (@ActualExtraVal17 = 'Null' and @StatementVal17= 'Null'))
    BEGIN
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName17 + ' = ' + @StatementVal17  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName17 + '] For [' + @dboTblname + ']'
      Print @Msg      
    END
END
If (@ForceExtraCompare18 = 1)
BEGIN
 	 If (@ActualExtraVal18 IS NULL and @StatementVal18 = 'Null')
 	 BEGIN
 	  	 Select @Msg = ''
 	 END
 	 ELSE IF ((@ActualExtraVal18 IS NULL and @StatementVal18 IS NOT NULL) OR (@ActualExtraVal18 IS NOT NULL and @StatementVal18 IS NULL) OR (@ActualExtraVal18 <> @StatementVal18) OR (@ActualExtraVal18 = 'Null' and @StatementVal18= 'Null'))
    BEGIN
      Select @StatementMIDDLE1 = 'Update ' + @dboTblname + ' Set ' + @ExtraColName18 + ' = ' + @StatementVal18  + @WhereClause
      Execute (@StatementMIDDLE1)
      Select @Msg = '-- Updated Static Table Column [' + @ExtraColName18 + '] For [' + @dboTblname + ']'
      Print @Msg      
    END
END
