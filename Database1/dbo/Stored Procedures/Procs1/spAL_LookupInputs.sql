Create Procedure dbo.spAL_LookupInputs
@Var_id int,
@ResultOn Datetime,
@DecimalSep char(1) = '.'
AS
Select @DecimalSep = COALESCE(@DecimalSep,'.')
Select Member = cid.Var_Id,
       v2.Var_Desc,
       v2.Group_Id,
       v2.DS_Id,
       v2.Data_Type_Id,
       v2.Var_Precision,
       v2.ESignature_Level,
       t.Test_Id,
       result = CASE 
              WHEN @DecimalSep <> '.' and v2.Data_Type_Id = 2 THEN REPLACE(T.Result, '.', @DecimalSep)
              ELSE T.Result
              END
  From Calculation_Instance_Dependencies cid
  Join Variables v on v.Var_Id = @Var_id
  Join Variables v2 on v2.Var_Id = cid.Var_Id
  Left Outer Join Tests t on t.Var_Id = cid.Var_Id and t.Result_On = @ResultOn
  Where cid.Result_Var_Id = @Var_id
  Order By v2.Var_Desc
/* Return the non-individual children variables (Range, Standard Deviation, Moving Range) and the Average*/
Select v.Var_Id,
       v.SPC_Group_Variable_Type_Id,
       result = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(T.Result, '.', @DecimalSep)
              ELSE T.Result
              END
  From Variables v
  Join Tests t on t.Var_Id = v.Var_Id and t.Result_On = @ResultOn
  Where v.PVar_Id = @Var_Id and v.SPC_Group_Variable_Type_Id in (2, 3, 4)
Union
Select Null,
       v.SPC_Group_Variable_Type_Id,
       result = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(T.Result, '.', @DecimalSep)
              ELSE T.Result
              END
  From Tests t 
  Join variables v on v.Var_Id = @Var_Id
  Where t.Var_Id = @Var_Id and t.Result_On = @ResultOn
