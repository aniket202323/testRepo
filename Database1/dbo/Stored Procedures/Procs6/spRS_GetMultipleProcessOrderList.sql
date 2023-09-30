Create Procedure [dbo].[spRS_GetMultipleProcessOrderList]
(@PID varchar(7000)
)
AS
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
Create Table #T (OrderID Int,Var_Id Int)
Select @I = 1
Select @INstr = @PID + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
    insert into #T (OrderId,Var_Id) Values (@I,@Id)
    Select @I = @I + 1
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
Select #t.Var_Id 
  	 , pp.Process_Order 
  	 from #t
 	 Join Production_Plan pp on #t.Var_Id = pp.PP_Id
 	  
