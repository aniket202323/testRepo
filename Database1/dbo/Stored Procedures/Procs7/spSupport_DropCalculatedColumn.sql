CREATE Procedure dbo.spSupport_DropCalculatedColumn 
 	 @TableName  	 Varchar(100),
 	 @ColumnName VarCHar(100),
 	 @DataType 	 VarChar(100),
 	 @ConstraintName 	 VarChar(100) = Null,
 	 @ConstraintCol1 VarChar(100) = Null
As
Declare @Sql VarChar(7000)
 	 Select @Sql = 'ALTER TABLE [dbo].[' + @TableName + '] Drop Column [' + @ColumnName + ']'
 	 Execute (@Sql)
 	 Select @Sql = 'Alter Table [dbo].[' + @TableName + '] Add  ' + @ColumnName + ' ' +  @DataType + ' Null'
 	 Execute (@Sql)
 	 Select @Sql = 'Update [dbo].[' + @TableName + '] Set ' + @ColumnName + ' = ' +  @ColumnName + '_Local'
 	 Execute (@Sql)
 	 Select @Sql = 'ALTER TABLE [dbo].[' + @TableName + '] ALTER COLUMN [' + @ColumnName + '] ' +  @DataType + ' NOT NULL'
 	 Execute (@Sql)
 	 If @ConstraintName is Not Null
 	   Begin
 	  	 If @ConstraintCol1 is Null
 	  	  	 Select @Sql = 'ALTER TABLE [dbo].[' + @TableName + '] ADD CONSTRAINT [' + @ConstraintName + '] UNIQUE  NONCLUSTERED ([' + @ColumnName +  '])'
 	  	 Else
 	  	  	 Select @Sql = 'ALTER TABLE [dbo].[' + @TableName + '] ADD CONSTRAINT [' + @ConstraintName + '] UNIQUE  NONCLUSTERED ([' + @ColumnName + '],[' + @ConstraintCol1 + '])'
 	  	 Execute (@Sql)
 	  	 Select @Sql = 'ALTER TABLE [dbo].[' + @TableName + '] DROP CONSTRAINT [' + @ConstraintName + 'Local' + ']'
 	  	 Execute (@Sql)
 	   End
 	 Select @Sql = 'Alter Table [dbo].[' + @TableName + '] Drop Column  [' + @ColumnName + '_Global] '
 	 Execute (@Sql)
 	 Select @Sql = 'Alter Table [dbo].[' + @TableName + '] Drop Column  [' + @ColumnName + '_Local] '
 	 Execute (@Sql)
