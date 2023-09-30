Create Procedure dbo.spAL_VariableHierarchy
@Event_Type tinyint 
AS
SELECT PL_Id, PL_Desc FROM Prod_Lines where pl_id > 0 Order by PL_Desc
SELECT PU_Id, PU_Desc, PL_Id FROM Prod_Units  where pu_id > 0 Order By PU_Desc
if (@Event_Type is null) 
  SELECT Var_Id, Var_Desc, PU_Id FROM Variables where pu_id > 0 Order by Var_Desc
else
  if (@Event_Type = 1) 
    SELECT Var_Id, Var_Desc, PU_Id FROM Variables where Event_Type = 1 and pu_id > 0 Order by Var_Desc
  else
    SELECT Var_Id, Var_Desc, PU_Id FROM Variables where ((Event_Type = 0) or (event_type = 5)) and pu_id > 0 Order by Var_Desc
