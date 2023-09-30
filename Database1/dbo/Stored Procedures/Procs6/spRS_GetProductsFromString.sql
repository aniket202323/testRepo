CREATE PROCEDURE [dbo].[spRS_GetProductsFromString] 
@VarString varchar(8000),
@Order int = 0
AS
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
Create Table #T (OrderID Int, Prod_Id Int)
Select @I = 1
Select @INstr = @VarString + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
    insert into #T (OrderId, Prod_Id) Values (@I,@Id)
    Select @I = @I + 1
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
If @Order = 0
  Select #T.Prod_Id, Products.Prod_Desc
  from #T 
  join Products on #T.Prod_Id = Products.Prod_Id
  order by OrderID
Else
  Select #T.Prod_Id, Products.Prod_Code 
  from #T 
  join Products on #T.Prod_Id = Products.Prod_Id
  order by OrderID
drop table #T
