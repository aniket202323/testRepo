create Procedure [dbo].[spWO_InitVariableSearch]
@VariableId int
AS
Select LineId = pl.PL_Id, UnitId = v.PU_id, GroupId = v.pug_id
  From Variables v
  Join Prod_Units p on p.pu_id = v.pu_id
  Join Prod_Lines pl on pl.PL_Id = p.pl_id 
  Where v.Var_Id = @VariableId
