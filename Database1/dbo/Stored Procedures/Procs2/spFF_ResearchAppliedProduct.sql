Create Procedure dbo.spFF_ResearchAppliedProduct
@SheetId int,
@EventId int
AS
Declare @TimeStamp datetime
Select @TimeStamp = TimeStamp
  From Events
  Where Event_Id = @EventId
If @TimeStamp Is Null Return
Select Var_Id 
  Into #Vars
  From Sheet_Variables 
  Where Sheet_Id = @SheetId
Select t.var_id, t.result 
  Into #Tests
  From Tests t
  Join #Vars V on t.var_id = v.var_id
  Where t.result_on = @TimeStamp and
        t.result is not null
Select vs.*, t.result 
  Into #SpecsWithTests
  From var_specs vs
  Join #Tests t on t.var_id = vs.var_id 
  Where vs.Effective_date <= @TimeStamp and ((vs.expiration_date > @TimeStamp) or (vs.expiration_date is null))
Delete From #SpecsWithTests
   Where prod_id in 
  (
    Select prod_id 
    from #SpecsWithTests 
    Where ((convert(real,result) < convert(real,l_reject)) and (l_reject is not null)) 
       or ((convert(real,result) > convert(real,u_reject)) and (u_reject is not null)) 
  )
Select Distinct s.prod_id, p.prod_code 
  From #SpecsWithTests s
  Join Products p on p.prod_id = s.prod_id
  Order By Prod_Code
Drop Table #Vars
Drop Table #Tests
Drop Table #SpecsWithTests
