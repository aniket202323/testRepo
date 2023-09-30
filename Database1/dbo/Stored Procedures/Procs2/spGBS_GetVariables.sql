Create Procedure dbo.spGBS_GetVariables 
@SheetName nvarchar(50)
AS
Declare @SheetId int
create table #Vars (
  VarId int NULL,
  VarOrder int NULL,
  Title nvarchar(100) NULL
)
Select @SheetId = Sheet_Id
  From Sheets
  Where Sheet_Desc = @SheetName
Insert Into #Vars
  Select Var_id, Var_Order, Title
    From Sheet_Variables
    Where Sheet_Id = @SheetId 
select a.*, b.pug_desc, v.Title, v.VarOrder 
  from #Vars v
  left outer join variables a on v.VarId = a.Var_Id
  left outer join pu_groups b on b.pug_id = a.pug_id
  order by v.VarOrder
Drop Table #Vars
