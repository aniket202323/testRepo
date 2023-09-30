CREATE PROCEDURE dbo.spEM_FindUnitCalcs
  @PU_Id int AS
  --
  -- Select the result variables of all calculations whose result
  -- variable is not in the specified production unit with at least
  -- one member variable in the specified production unit.
Declare @VarId Int
Declare @PUGId Int
Create Table #UCalcVar (Rslt_Var_Id Int)
Declare UCalcCursor cursor 
  For Select PUG_Id From PU_Groups where  PU_Id = @PU_Id
  For Read only
Open UCalcCursor
Loop:
  Fetch Next From  UCalcCursor InTo @PUGId
If @@Fetch_Status = 0
  Begin
 	 Declare GCalcCursor cursor 
 	   For Select Var_Id From Variables where  PUG_Id = @PUGId
 	   For Read only
 	 Open GCalcCursor
Loop1:
 	   Fetch Next From  GCalcCursor InTo @VarId
 	 If @@Fetch_Status = 0
 	   Begin
 	     Insert into #UCalcVar 
 	      Execute spEM_FindVariableCalcs @VarId
 	     GoTo Loop1
 	   End
 	 Close GCalcCursor
 	 Deallocate GCalcCursor
    GoTo Loop
  End
Close UCalcCursor
Deallocate UCalcCursor
SELECT Rslt_Var_Id 
   From #UCalcVar c
   Join Variables v on v.Var_Id = c.Rslt_Var_Id
   Where v.PU_Id <> @PU_Id
DROP TABLE #UCalcVar
