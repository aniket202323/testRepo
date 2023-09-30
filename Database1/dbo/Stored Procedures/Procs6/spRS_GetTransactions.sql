CREATE PROCEDURE dbo.spRS_GetTransactions
@GroupId int = Null,
@ExcludeStr varchar(8000) = Null,
@Flag int = 0
 AS
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
Create Table #T (OrderId int, MyId Int)
Select @I = 1
Select @INstr = @ExcludeStr + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
    insert into #T (OrderId, MyId) Values (@I,@Id)
    Select @I = @I + 1
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
If @Flag = 0
  Begin
 	 If @GroupId Is Null
 	   Begin
 	     If @ExcludeStr Is Null
 	       Begin
 	         Select Trans_Id, Trans_Desc From Transactions Where Transaction_Grp_Id is null
 	       End
 	     Else
 	       Begin
 	         Select Trans_Id, Trans_Desc From Transactions Where Transaction_Grp_Id is null and Trans_Id Not In (Select MyId from #t)
 	       End
 	   End
 	 Else
 	   Begin
 	     If @ExcludeStr Is Null
 	       Begin
 	         Select Trans_Id, Trans_Desc From Transactions Where Transaction_Grp_Id = @GroupId
 	       End
 	     Else
 	       Begin
 	         Select Trans_Id, Trans_Desc From Transactions Where Transaction_Grp_Id = @GroupId and Trans_Id Not In (Select MyId from #t)
 	       End
 	     
 	   End
  End
Else
  Begin
 	 Select MyId, t.Trans_Desc From #t Join Transactions t on t.Trans_Id = #t.MyId
  End
DROP TABLE #T
