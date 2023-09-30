Create Procedure dbo.spEM_GetCalcData
  @Rslt_Var_Id int,
  @Calc_Id     int           OUTPUT,
  @Calculation nvarchar(255)  OUTPUT,
  @Mem1_Var_Id int           OUTPUT,
  @Mem2_Var_Id int           OUTPUT,
  @Mem3_Var_Id int           OUTPUT,
  @Mem4_Var_Id int           OUTPUT,
  @Mem5_Var_Id int           OUTPUT,
  @Mem6_Var_Id int           OUTPUT,
  @Mem7_Var_Id int           OUTPUT,
  @Mem8_Var_Id int           OUTPUT
  AS
  --
  SELECT @Calc_Id     = Calc_Id,
         @Calculation = Calculation,
         @Mem1_Var_Id = Mem1_Var_Id,
         @Mem2_Var_Id = Mem2_Var_Id,
         @Mem3_Var_Id = Mem3_Var_Id,
         @Mem4_Var_Id = Mem4_Var_Id,
         @Mem5_Var_Id = Mem5_Var_Id,
         @Mem6_Var_Id = Mem6_Var_Id,
         @Mem7_Var_Id = Mem7_Var_Id,
         @Mem8_Var_Id = Mem8_Var_Id
  FROM Calcs WHERE Rslt_Var_Id = @Rslt_Var_Id
  RETURN(0)
