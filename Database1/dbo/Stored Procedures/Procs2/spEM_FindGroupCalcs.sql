CREATE PROCEDURE dbo.spEM_FindGroupCalcs
  @PUG_Id int AS
  --
  -- Select the result variables of all calculations whose result
  -- variable is not in the specified production group with at least
  -- one member variable in the specified production group.
  --
Declare @VarId Int
Create Table #CalcVar (Rslt_Var_Id Int)
Declare GCalcCursor cursor 
  For Select Var_Id From Variables where  PUG_Id = @PUG_Id
  For Read only
Open GCalcCursor
Loop:
  Fetch Next From  GCalcCursor InTo @VarId
If @@Fetch_Status = 0
  Begin
    Insert into #CalcVar 
     Execute spEM_FindVariableCalcs @VarId
    GoTo Loop
  End
Close GCalcCursor
Deallocate GCalcCursor
SELECT Rslt_Var_Id 
   From #CalcVar c
   Join Variables v on v.Var_Id = c.Rslt_Var_Id
   Join  PU_Groups pug on pug.PUG_Id = v.PUG_Id and  PUG_Desc <> 'Model 5014 Calculation'
   Where v.PUG_Id <> @PUG_Id
DROP TABLE #CalcVar
