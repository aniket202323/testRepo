create procedure dbo.spSupport_VerifyDB_TableColumn
@Tblname varchar(100),
@FieldName varchar(100),
@TrueFieldType varchar(30),
@TrueFieldLen int,
@TrueIsIdent int,
@TrueIsNullable int,
@TrueIsDefaultable int,
@TruePrec int,
@TrueScale int
AS
Declare
  @TableId int,
  @ColId int,
  @FieldType varchar(30),
  @IsIdent int,
  @IsNullable int,
  @IsDefaultable int,
  @DefId int,
  @DefName varchar(255),
  @FieldLen int,
  @Msg varchar(255),
  @Statement varchar(1000),
  @Prec int,
  @Scale int,
  @ShouldAlterColumn int,
  @Num int,
  @IsComputed 	  	 int,
  @XType int
If @TrueFieldType in('varchar','nvarchar') and @TrueFieldLen = -1
BEGIN
 	 SET @TrueFieldType = @TrueFieldType + '(Max)'
END
If (@TrueFieldType = 'varchar') and @TrueFieldLen > 0
  Select @TrueFieldType = 'varchar(' + convert(varchar(10),@TrueFieldLen) + ')'
If (@TrueFieldType = 'char')  
  Select @TrueFieldType = 'char(' + convert(varchar(10),@TrueFieldLen) + ')'
If (@TrueFieldType = 'nvarchar') and @TrueFieldLen > 0
  Select @TrueFieldType = 'nvarchar(' + convert(varchar(10),(@TrueFieldLen/2)) + ')'
If (@TrueFieldType = 'nchar')
  Select @TrueFieldType = 'nchar(' + convert(varchar(10),(@TrueFieldLen/2)) + ')'
If (@TrueFieldType = 'decimal') 
  Select @TrueFieldType = 'decimal(' + convert(varchar(10),@TruePrec) + ',' + convert(varchar(10),@TrueScale) + ')'
SELECT @Tblname = 'dbo.' + @Tblname
Select @TableId = NULL
Select @TableId = object_id(@Tblname) 
If (@TableId Is NULL)
BEGIN
    Select @Statement = 'CREATE TABLE ' + @Tblname + '(' + @FieldName + ' ' + @TrueFieldType + ' '
    If (@TrueIsIdent = 1)
      Select @Statement = @Statement + ' IDENTITY (1, 1) '
    If (@TrueIsNullable = 1)
      Select @Statement = @Statement + ' NULL '
    Else
      Select @Statement = @Statement + ' NOT NULL '
    Select @Statement = @Statement + ')'
    Execute (@Statement)
    Select @Statement = '-- Added Table [' + @Tblname + ']'
    Print @Statement
    Select @Statement = '-- Added Table Column [' + @Tblname + '] [' + @FieldName + '] [' + @TrueFieldType + ']'
    Print @Statement
    Return
END
/*  do not add to existing */
IF (@FieldName =  Replace(@Tblname,'dbo.','') + '_Id') AND (@Tblname Like '%_History') 
 	 RETURN
Select @ColId = NULL
Select @ColId = colid,
       @IsIdent = Case (Status & 128) When 0 Then 0 Else 1 End,
       @IsNullable = Case (Status & 8) When 0 Then 0 Else 1 End,
       @IsDefaultable = Case cDefault When 0 Then 0 Else 1 End,
       @FieldLen = Length,
       @Prec = xprec,
       @Scale = scale,
 	    @XType = xtype,
 	    @IsComputed = iscomputed
   From sys.syscolumns 
   Where (Id = @TableId) And
         (Name = @FieldName)
--only handling upgrade scenario
SET @TrueFieldType = Case when @XType = 99  Then Replace(Replace(@TrueFieldType,'Char','nChar') ,'nnChar','nchar') when @xtype = 231 then  Replace(Replace(@TrueFieldType,'varchar','nVarchar') ,'nnvarchar','nVarchar') when @XType = 239 Then Replace(Replace(@TrueFieldType,'text','ntext'),'nntext','ntext') else @TrueFieldType End
If (@ColId Is Not NULL)
BEGIN
    Select @FieldType = Substring(b.Name,1,29)
      From sys.syscolumns a
      Join sys.systypes b on (b.Usertype = a.Usertype) And (b.xtype = a.xtype)
      Where (a.Id = @TableId) And
            (a.Name = @FieldName)
 	  	  	 If @FieldType in('varchar','nvarchar') and @FieldLen = -1
 	  	  	 BEGIN
 	  	  	  	 SET @FieldType = @FieldType + '(Max)'
 	  	  	 END
    If (@FieldType = 'varchar') and @FieldLen > 0 
      Select @FieldType = 'varchar(' + convert(varchar(10),@FieldLen) + ')'
    If (@FieldType = 'char') 
      Select @FieldType = 'char(' + convert(varchar(10),@FieldLen) + ')'
    If (@FieldType = 'nvarchar') and @FieldLen > 0 
      Select @FieldType = 'nvarchar(' + convert(varchar(10), (@FieldLen/2)) + ')'
    If (@FieldType = 'nchar')
      Select @FieldType = 'nchar(' + convert(varchar(10), (@FieldLen/2)) + ')'
    If (@FieldType = 'decimal') 
      Select @FieldType = 'decimal(' + convert(varchar(10),@Prec) + ',' + convert(varchar(10),@Scale) + ')'
 	   
END
If (@ColId Is NULL)
BEGIN
 	 Select @Statement = 'ALTER TABLE ' + @Tblname + ' ADD ' + @FieldName + ' ' + @TrueFieldType + ' '
 	 If (@TrueIsIdent = 1)
      Select @Statement = @Statement + ' IDENTITY (1, 1) '
    If (@TrueIsNullable = 1)
      Select @Statement = @Statement + ' NULL '
    Else 
 	 If (@TrueIsIdent <> 1)
 	 BEGIN
 	  	 If (@TrueFieldType = 'uniqueidentifier')
 	  	  	 Select @Statement = @Statement + ' NOT NULL CONSTRAINT TmpDef' + @FieldName + ' DEFAULT (''' + '6F9619FF-8B86-D011-B42D-00C04FC964FF' + ''')'
 	  	 Else
 	  	 If (Substring(@TrueFieldType,1,7) = 'decimal')
 	  	   Select @Statement = @Statement + ' NOT NULL CONSTRAINT TmpDef' + @FieldName + ' DEFAULT (0.0)'
 	  	 Else
 	  	   Select @Statement = @Statement + ' NOT NULL CONSTRAINT TmpDef' + @FieldName + ' DEFAULT (''' + ''')'
 	 END
    Execute (@Statement)
    If (@TrueIsNullable <> 1) and (@TrueIsIdent <> 1)
 	 BEGIN
        Select @Statement = 'Alter Table ' + @Tblname + ' Drop Constraint TmpDef' + @FieldName 
        Execute (@Statement)
 	 END
    Select @Statement = '-- Added Table Column [' + @Tblname + '] [' + @FieldName + '] [' + @TrueFieldType + ']'
    Print @Statement 
    Return
END
Select @ShouldAlterColumn = 0
If (@TrueFieldType <> @FieldType)
Begin
    If NOT ((@TrueFieldType = 'bit') And (@FieldType = 'tinyint'))
    If NOT ((@TrueFieldType = 'real') And (substring(@FieldType,1,7) = 'decimal'))
    If NOT ((substring(@TrueFieldType,1,7) = 'decimal') And (@FieldType = 'real'))
    If NOT ((@TrueFieldType = 'real') And (@FieldType = 'float'))
    If NOT ((@TrueFieldType = 'float') And (@FieldType = 'real'))
    If NOT ((@TrueFieldType = 'int') And (@FieldType = 'bigint'))
    If NOT ((@TrueFieldType = 'bigint') And (@FieldType = 'int'))
      Select @ShouldAlterColumn = 1
 End
If (@TrueIsNullable <> @IsNullable) and (@TrueFieldType = @FieldType)  -- Only do null if no datatype change
  Select @ShouldAlterColumn = 1
If  @IsComputed = 1 
 	 Select @ShouldAlterColumn = 0
If (@ShouldAlterColumn = 1)
  If (@TrueFieldType = 'text') Or (@FieldType = 'text') Or (@TrueFieldType = 'ntext') Or (@FieldType = 'ntext')
    Begin
      Select @Msg = '-- Warning: TEXT Column can not be altered for [' + @FieldName + '] On [' + @Tblname + ']'
      Print @Msg
    End
  Else
    Begin
      If (@IsDefaultable = 1)
        Begin
          Select @DefId = NULL
          Select @DefId = cDefault From sys.syscolumns Where (Id = @TableId) And (Name = @FieldName)
          If (@DefId Is Not NULL)
            Begin
              Select @DefName = NULL
              Select @DefName = Name From sys.sysobjects Where (Id = @DefId) And (Type = 'D')
              If (@DefName Is Not NULL)
                Begin
                  Select @Statement = 'Alter Table ' + @Tblname + ' DROP CONSTRAINT ' + @DefName
                  Execute (@Statement)
                End
            End
        End
      If (@TrueIsNullable = 1)
        Begin
          Select @Statement = 'ALTER TABLE ' + @Tblname + ' ALTER COLUMN ' + @FieldName + ' ' + @TrueFieldType + ' NULL'
          Execute (@Statement)
          Select @Msg = '-- Altered Column [' + @FieldName + '] On [' + @Tblname + ']'
          Print @Msg
        End
      Else
        Begin
          Create Table #TmpCntHolder (Num int NULL)
          Select @Statement = 'Insert Into #TmpCntHolder(Num) (Select Count(*) From ' + @TblName + ' Where ' + @FieldName + ' Is NULL)'
          Execute (@Statement)
          Select @Num = NULL
          Select @Num = Num From #TmpCntHolder
          Drop Table #TmpCntHolder 
          If (@Num Is NULL) Or (@Num = 0)
            Begin            
              Select @Statement = 'ALTER TABLE ' + @Tblname + ' ALTER COLUMN ' + @FieldName + ' ' + @TrueFieldType + ' NOT NULL'
              Execute (@Statement)
              Select @Msg = '-- Altered Column [' + @FieldName + '] On [' + @Tblname + ']'
              Print @Msg
            End
          Else
            Begin
              Select @Msg = '-- Warning: Column Should Not Be NULLABLE. NULL Values Exist [' + @FieldName + '] On [' + @Tblname + ']'
              Print @Msg
            End
        End
    End
If (@TrueIsIdent <> @IsIdent)
  Begin
    Select @Msg = '-- Warning: Mismatch On Identity [' + @FieldName + '] On [' + @Tblname + ']'
    Print @Msg
  End
--If (@TrueFieldLen <> @FieldLen)
--  Begin
--    Select @Msg = '-- Warning: Mismatch on FieldLength [' + @Tblname + '] Column [' + @FieldName + '] Should Be [' + Convert(varchar(10),@TrueFieldLen) + '] Not [' + Convert(varchar(10),@FieldLen) + ']'
--    Print @Msg
--  End
