CREATE PROCEDURE dbo.spEM_FindLineCalcs
  @PL_Id int AS
  --
  -- Create a temporary table containing all the units on the
  -- production line.
  --
Declare @PUId Int
Declare @VarId Int
Declare @PUGId Int
Create Table #LCalcVar (Rslt_Var_Id Int)
Declare LCalcCursor cursor 
  For Select PU_Id From Prod_Units where  PL_Id = @PL_Id
  For Read only
Open LCalcCursor
Loop:
  Fetch Next From  LCalcCursor InTo @PUId
If @@Fetch_Status = 0
  Begin
   Declare UCalcCursor cursor 
          For Select PUG_Id From PU_Groups where  PU_Id = @PUId
    For Read only
    Open UCalcCursor
    Loop1:
    Fetch Next From  UCalcCursor InTo @PUGId
    If @@Fetch_Status = 0
    Begin
 	 Declare GCalcCursor cursor 
 	   For Select Var_Id From Variables where  PUG_Id = @PUGId
 	   For Read only
 	 Open GCalcCursor
 	 Loop2:
 	   Fetch Next From  GCalcCursor InTo @VarId
 	 If @@Fetch_Status = 0
 	   Begin
 	      Insert into #LCalcVar 
 	        Execute spEM_FindVariableCalcs @VarId
 	     GoTo Loop2
 	   End
 	 Close GCalcCursor
 	 Deallocate GCalcCursor
    GoTo Loop1
  End
  Close UCalcCursor
  Deallocate UCalcCursor
  GoTo Loop
 End
Close LCalcCursor
Deallocate LCalcCursor
SELECT Rslt_Var_Id 
   From #LCalcVar c
   Join Variables v on v.Var_Id = c.Rslt_Var_Id
   Join  PU_Groups pug on pug.PUG_Id = v.PUG_Id and  PUG_Desc <> 'Model 5014 Calculation'
   Where v.PU_Id  Not In (Select PU_Id From Prod_Units where  PL_Id = @PL_Id)
DROP TABLE #LCalcVar
