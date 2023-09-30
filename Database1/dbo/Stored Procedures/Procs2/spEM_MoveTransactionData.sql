CREATE PROCEDURE dbo.spEM_MoveTransactionData
  @Trans_Id   Int,
  @IsNew      Int,
  @InServerId Int,
  @NewTransId Int Output
  AS
Declare @IsLinkedServer Bit,
 	 @ServerName  	 nvarchar(1000),
 	 @InServerName 	 nvarchar(50)
Create Table #TransId(TransId INt)
Select @IsLinkedServer = Linked_Server_IsLinked,@InServerName = Linked_Server_Desc
  From Linkable_Remote_Servers Where Linked_Server_Id = @InServerId
Declare @Sql VarChar(7000)
If @IsLinkedServer = 0 
  Begin
     Select @ServerName = 'OPENDATASOURCE(''' 
     Select @ServerName = @ServerName + 'SQLOLEDB''' + ',''' + 'Data Source=' + @InServerName + ';User ID=Comxclient;Password=comxclient'
     Select @ServerName = @ServerName + ''')'
  End
Else
  Select @ServerName = @InServerName
If @IsNew = 1
  Begin
 	 Select @Sql = 'Insert InTo '+  @ServerName + '.gbdb.dbo.Transactions '
 	 Select @Sql = @Sql + '(Trans_Create_Date,Corp_Trans_Id,Trans_Type_Id,Transaction_Grp_Id,Trans_Desc,Corp_Trans_Desc) '
 	 Select @Sql = @Sql + 'Select Trans_Create_Date,Trans_Id,2,1,Trans_Desc,''' 
 	 Select @Sql = @Sql + Convert(nvarchar(50),@@Servername) + ''' From Transactions '
 	 Select @Sql = @Sql + 'Where Trans_Id = ' + Convert(nVarChar(10),@Trans_Id)
 	 Execute (@Sql)
 	 Select @Sql = 'Insert into #TransId Select Trans_Id From '+  @ServerName + '.gbdb.dbo.Transactions '
 	 Select @Sql = @Sql + 'Where Corp_Trans_Id = ' + Convert(nVarChar(10),@Trans_Id)
 	 Execute(@Sql)
 	 Select @NewTransId = TransId from #TransId
 	 Drop Table #TransId
 	 Select @Sql = 'Insert InTo '+  @ServerName + '.gbdb.dbo.Trans_Variables  (Test_Freq,Esignature_Level,L_Warning,L_Reject,L_Entry,L_User,Target,U_User,U_Entry,U_Reject,U_Warning,L_Control,T_Control,U_Control,Trans_Id,Var_Id,Prod_Id) '
 	 Select @Sql = @Sql + 'Select Test_Freq,tv.Esignature_Level,L_Warning,L_Reject,L_Entry,L_User,Target,U_User,U_Entry,U_Reject,U_Warning,L_Control,T_Control,U_Control,'
 	 Select @Sql = @Sql + Convert(nVarChar(10),@NewTransId) + ',rv.Var_Id,rp.Prod_Id '
 	 Select @Sql = @Sql + 'From Trans_Variables tv '
 	 Select @Sql = @Sql + 'Join Variables v on v.var_Id = tv.var_Id '
 	 Select @Sql = @Sql + 'Left Join ' +   @ServerName + '.gbdb.dbo.Variables rv On rv.test_Name = v.Test_Name '
 	 Select @Sql = @Sql + 'Join Products p on p.Prod_Id = tv.Prod_Id '
 	 Select @Sql = @Sql + 'Left Join ' +   @ServerName + '.gbdb.dbo.Products rp On rp.Prod_Code = p.Prod_Code '
 	 Select @Sql = @Sql + 'Where Trans_Id = ' + Convert(nVarChar(10),@Trans_Id)
 	 Execute (@Sql)
  End
Else
  Begin
 	 Select @Sql = 'Insert into #TransId Select Corp_Trans_Id From '+  @ServerName + '.gbdb.dbo.Transactions '
 	 Select @Sql = @Sql + 'Where Trans_Id = ' + Convert(nVarChar(10),@Trans_Id)
 	 Execute(@Sql)
 	 Select @NewTransId = TransId from #TransId
 	 Drop Table #TransId 	 Select @Sql = 'Delete From '+  @ServerName + '.gbdb.dbo.Trans_Variables '
 	 Select @Sql = @Sql + 'Where Trans_Id = ' + Convert(nVarChar(10),@Trans_Id)
 	 Execute (@Sql)
 	 Select @Sql = 'Delete From '+  @ServerName + '.gbdb.dbo.Transactions '
 	 Select @Sql = @Sql + 'Where Trans_Id = ' + Convert(nVarChar(10),@Trans_Id)
 	 Execute (@Sql)
  End
