CREATE Procedure dbo.spSupport_CreateCalculatedColumn 
 	 @TableName  	 Varchar(100),
 	 @ColumnName VarCHar(100),
 	 @DataType 	 VarChar(100),
 	 @ConstraintName 	 VarChar(100) = Null,
 	 @ConstraintCol1 VarChar(100) = Null
As
Declare @Sql VarChar(7000)
 	 Select @Sql = 'Alter Table [dbo].[' + @TableName + '] Add  ' + @ColumnName + '_Global ' +  @DataType + ' NULL'
 	 Execute (@Sql)
 	 Select @Sql = 'Alter Table [dbo].[' + @TableName + '] Add  ' + @ColumnName + '_Local ' +  @DataType + ' NULL'
 	 Execute (@Sql)
 	 Select @Sql = 'Update [dbo].[' + @TableName + '] Set ' + @ColumnName + '_Local = ' +  @ColumnName
 	 Execute (@Sql)
 	 Select @Sql = 'ALTER TABLE [dbo].[' + @TableName + '] ALTER COLUMN [' + @ColumnName + '_Local] ' +  @DataType + ' NOT NULL'
 	 Execute (@Sql)
 	 If @ConstraintName is not null
 	   Begin
 	  	 If @ConstraintCol1 is Null
 	  	  	 Select @Sql = 'ALTER TABLE [dbo].[' + @TableName + '] ADD CONSTRAINT [' + @ConstraintName + 'Local' + '] UNIQUE  NONCLUSTERED ([' + @ColumnName + '_Local' + '])'
 	  	 Else
 	  	  	 Select @Sql = 'ALTER TABLE [dbo].[' + @TableName + '] ADD CONSTRAINT [' + @ConstraintName + 'Local' + '] UNIQUE  NONCLUSTERED ([' + @ColumnName + '_Local' + '],[' + @ConstraintCol1 + '])'
 	  	 Execute (@Sql)
 	  	 Select @Sql = 'ALTER TABLE [dbo].[' + @TableName + '] DROP CONSTRAINT [' + @ConstraintName + ']'
 	  	 Execute (@Sql)
 	   End
 	 Select @Sql = 'ALTER TABLE [dbo].[' + @TableName + '] Drop Column [' + @ColumnName + ']'
 	 Execute (@Sql)
 	 Select @Sql = 'Alter table [dbo].[' + @TableName + '] Add ' + @ColumnName + ' AS (case when @@options & 512 = 0 then  isnull([' + @ColumnName + '_Global],[' + @ColumnName + '_Local])  else [' + @ColumnName + '_Local] end)'
 	 Execute (@Sql)
