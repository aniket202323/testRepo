CREATE PROCEDURE [dbo].[spRS_MakeOrderedResultSet]
@InputString varchar(7000)
AS
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
Create Table #T (Id_Order Int,Id_Value Int)
Select @I = 1
Select @INstr = @InputString + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
    insert into #T (Id_Order, Id_Value) Values (@I,@Id)
    Select @I = @I + 1
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
Select * from #t
drop table #t
