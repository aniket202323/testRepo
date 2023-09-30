Create  PROCEDURE dbo.spEM_GetRemoteTransactionData 
 @InServerName nvarchar(50)
  AS
Declare @IsLinkedServer Bit
Declare @ServerId 	 Int
Declare @ServerName nvarchar(1000)
Select @IsLinkedServer = Linked_Server_IsLinked,@ServerId = Linked_Server_Id
  From Linkable_Remote_Servers Where Linked_Server_Desc = @InServerName
Declare @Sql VarChar(7000)
If @IsLinkedServer = 0 
  Begin
     Select @ServerName = 'OPENDATASOURCE(''' 
     Select @ServerName = @ServerName + 'SQLOLEDB''' + ',''' + 'Data Source=' + @InServerName + ';User ID=Comxclient;Password=comxclient'
     Select @ServerName = @ServerName + ''')'
  End
Else
  Select @ServerName = @InServerName
Select @Sql = 'Select Linked_Server_Id =  ' + Convert(nVarChar(10),@ServerId) + ',Trans_Id,Corp_Trans_Id,Trans_Desc,Trans_Create_Date,Approved_On,Effective_Date '
Select @Sql = @Sql + 'From ' +  @ServerName + '.gbdb.dbo.Transactions t '
Select @Sql = @Sql + 'Where Corp_Trans_Id is not null and Trans_Type_Id = 2 and Corp_Trans_Desc = ''' + @@ServerName + ''''
Execute (@Sql)
