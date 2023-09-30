CREATE PROCEDURE [dbo].[spRS_GetVariablesFromString] 
@VarString varchar(8000)
AS
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
Create Table #T (OrderID Int,Var_Id Int)
Select @I = 1
Select @INstr = @VarString + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
    insert into #T (OrderId,Var_Id) Values (@I,@Id)
    Select @I = @I + 1
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
Select #T.Var_Id, Variables.Var_Desc 
from #T 
join Variables on #T.var_Id = Variables.var_Id
order by OrderID
drop table #T
