CREATE PROCEDURE dbo.spEM_IEPutImportData 
  @DataType     nVarChar(100),
  @InputString  Varchar(7000),
  @UserId 	  	 Int,
  @TransId 	  	 Int,
  @TransType 	 nVarChar(1),
  @Success 	     nvarchar(255) Output
  AS
Declare @Sql VarChar(7000), @TransNeeded Integer,@TransTypeNeeded Integer
Select @Sql = ''''
Select @Sql = @Sql + replace(@InputString,'''','''''')
Select @Sql = replace(@Sql,Char(1),''',''')
Select @Sql = replace(@Sql,' 	 ',' ') --Remove any tabs - replace with spaces
Select @Sql = replace(@Sql,','''',',',Null,')
Select @Sql = replace(@Sql,','''',',',Null,')
Select @Sql = replace(@Sql,'''True''','1')
Select @Sql = replace(@Sql,'''False''','0')
Select @Sql = Left(@Sql,len(@Sql) - 1) + Convert(nVarChar(10),@UserId)
Create table #ReturnString(Success nvarchar(255))
Select  @Sql = 'spEM_IEImport' + @DataType + ' ' + @Sql
Select @TransNeeded = Is_Trans_Needed,@TransTypeNeeded = Is_Type_Needed 
 From Import_Export_Types
 Where IE_Type_Desc = @DataType
If @TransNeeded = 1 
 	 Begin
 	   Select @Sql =  @Sql + ',' + Convert(nVarChar(10),@TransId)
 	 End
If @TransTypeNeeded = 1 Or @TransTypeNeeded = 2
 	 Begin
 	   Select @Sql =  @Sql + ',''' + @TransType + ''''
 	 End
Insert into #ReturnString
 	 Execute(@Sql)
Select @Success = Success From #ReturnString
Drop table #ReturnString
