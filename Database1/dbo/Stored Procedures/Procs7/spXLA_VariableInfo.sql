-- DESC: spXLA_VariableInfo retrieve variable information based on input variable. MT/5-6-2002
-- ECR #25128: mt/3-13-2003: handle duplicate Var_Desc since GBDB doesn't enforced unique Var_Desc across the entire system.
--
CREATE PROCEDURE  dbo.spXLA_VariableInfo
 	   @Var_Id       Int
 	 , @Var_Desc      Varchar(50)
AS
DECLARE @VariableFetchCount 	 Integer
-- ECR #25128: mt/3-13-2003: handle duplicate Var_Desc since GBDB doesn't enforced unique Var_Desc across the entire system.
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --input variable NOT SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --we have @Var_Id
  BEGIN
    SELECT @Var_Desc = v.Var_Desc FROM Variables v  WHERE v.Var_Id = @Var_Id
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount = 0
      BEGIN
        SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND
        RETURN
      END
    --EndIf:Count=0   
  END
Else --@Var_Desc NOT null, use it
  BEGIN
    SELECT @Var_Id = v.Var_Id FROM Variables v WHERE v.Var_Desc = @Var_Desc
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount <> 1
      BEGIN
        If @VariableFetchCount = 0
          SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND
        Else --too many Var_Desc
          SELECT [ReturnStatus] = -33 	 --DUPLICATE FOUND in Var_Desc
        --EndIf:Count
        RETURN
      END
    --EndIf:Count<>1
  END
--EndIf:Both @Var_Id and @Var_Desc null
SELECT v.Var_Id
     , v.Var_Desc
     , v.Eng_Units
     , pu.Pu_Desc 
     , dt.Data_Type_Desc
     , s.Spec_Desc
     , v.Sampling_Interval
     , v.Sampling_Type     
     , v.Var_Precision     
     , v.Event_Type       
     , ds.Ds_Desc
     , v.Input_Tag
     , v.Output_Tag       
     , [Calculation_Name]   = calc.Calculation_Name
     , [Calculation_Type]   = ctype.Calculation_Type_Desc
     , [Calculation_Detail] = Case ctype.Calculation_Type_Id When 1 Then calc.Equation When 2 Then calc.Stored_Procedure_Name When 3 then calc.Script End
     , v.Rank
     , v.Comment_Id
     , v.External_Link
     , v.User_Defined1
     , v.User_Defined2
     , v.User_Defined3
  FROM Variables v 
  JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
  LEFT OUTER JOIN Data_Type dt ON dt.Data_Type_Id = v.Data_Type_Id
  LEFT OUTER JOIN Specifications s ON s.Spec_Id = v.Spec_Id
  LEFT OUTER JOIN Data_Source ds ON ds.Ds_Id = v.Ds_Id
  LEFT OUTER JOIN Calculations calc ON calc.Calculation_Id = v.Calculation_Id AND v.Ds_Id = 16
  LEFT OUTER JOIN Calculation_Types ctype ON ctype.Calculation_Type_Id = calc.Calculation_Type_Id
 WHERE v.Var_Id = @Var_Id 
