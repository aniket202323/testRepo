Create Procedure [dbo].spWAIC_GetUnitListByVariables
@Variables Varchar(8000)
AS
Create Table #Variables([Order] int, Var_Id int)
Insert Into #Variables([Order], Var_Id) Exec spRS_MakeOrderedResultSet @Variables
Select Distinct(v.PU_Id) 'Id', pu.PU_Desc 'Description'
From Variables v
Join Prod_Units pu On pu.PU_Id = v.PU_Id
Where v.Var_Id In (Select Var_Id From #Variables)
