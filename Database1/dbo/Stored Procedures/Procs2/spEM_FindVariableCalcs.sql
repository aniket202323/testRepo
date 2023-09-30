CREATE PROCEDURE dbo.spEM_FindVariableCalcs
  @Var_Id int AS
  -- Create a temporary table containing the variable and its children.
  SELECT Var_Id INTO #Var FROM Variables WHERE PVar_Id = @Var_Id
  UNION
  SELECT Var_Id = @Var_Id
  -- Find the calculations with results variables not in the set that
  -- have member variables in this set.
Create Table #TempDepend(Rslt_Var_Id int)
 Insert Into #TempDepend
    SELECT Result_Var_Id
      FROM Calculation_Dependency_Data
      WHERE  Result_Var_Id <> @Var_Id AND (Var_Id IN (SELECT Var_Id FROM #Var))
 Insert #TempDepend 
 	 SELECT Result_Var_Id 
 	   FROM Calculation_Input_Data
          WHERE Member_var_Id = @var_Id 	   And Result_Var_Id <> @var_Id
 Insert #TempDepend 
 	 SELECT Result_Var_Id 
 	   FROM Calculation_Instance_Dependencies
          WHERE var_Id = @var_Id  And Result_Var_Id <> @var_Id 
  SELECT Rslt_Var_Id  FROM #TempDepend 
  -- Drop the temporary table.
  DROP TABLE #Var
  DROP TABLE #TempDepend
