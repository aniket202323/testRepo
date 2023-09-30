Create Procedure dbo.spCHT_GetSPCTrendType 
@VarId int
AS
  Declare @Calculation_Type_Id int,
          @Variable_Type_Id int
  Select @Calculation_Type_Id = SPC_Calculation_Type_Id From Variables where Var_Id = @VarId
  If @Calculation_Type_Id = 4 --Range
    Select @Variable_Type_Id = 2
  If @Calculation_Type_Id = 5 --Standard Deviation
    Select @Variable_Type_Id = 3
  If @Calculation_Type_Id = 6 --Moving Range
    Select @Variable_Type_Id = 4
 	 Select v2.Var_Id as 'SPC_Var_Id', v.SPC_Calculation_Type_Id
 	     From Variables v
      Join Variables v2 on v2.PVar_Id = v.Var_Id and v2.SPC_Group_Variable_Type_Id = @Variable_Type_Id
 	       Where v.Var_Id = @VarId
