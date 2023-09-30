Create Procedure dbo.spEM_PutCalcData
  @Calculation nvarchar(255),
  @Rslt_Var_Id int,
  @Mem1_Var_Id int,
  @Mem2_Var_Id int,
  @Mem3_Var_Id int,
  @Mem4_Var_Id int,
  @Mem5_Var_Id int,
  @Mem6_Var_Id int,
  @Mem7_Var_Id int,
  @Mem8_Var_Id int,
  @User_Id int,
  @Calc_Id     int OUTPUT
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutCalcData',
                @Calculation + ','  + 
                Convert(nVarChar(10),@Rslt_Var_Id) + ','  + 
                Convert(nVarChar(10),@Mem1_Var_Id) + ','  + 
                Convert(nVarChar(10),@Mem2_Var_Id) + ','  + 
                Convert(nVarChar(10),@Mem3_Var_Id) + ','  + 
                Convert(nVarChar(10),@Mem4_Var_Id) + ','  + 
                Convert(nVarChar(10),@Mem5_Var_Id) + ','  + 
                Convert(nVarChar(10),@Mem6_Var_Id) + ','  + 
                Convert(nVarChar(10),@Mem7_Var_Id) + ','  + 
                Convert(nVarChar(10),@Mem8_Var_Id) + ','  + 
 	  	 Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create calc record.
  --
  -- Take action based upon weither we have a calculation identity specified.
  --
select @Calc_Id
  IF @Calc_Id IS NULL
    --
    -- Create a new calculation.
    --
    BEGIN
      INSERT INTO Calcs(Calculation, Rslt_Var_Id, Mem1_Var_Id, Mem2_Var_Id, Mem3_Var_Id,
                        Mem4_Var_Id, Mem5_Var_Id, Mem6_Var_Id, Mem7_Var_Id, Mem8_Var_Id)
        VALUES(@Calculation, @Rslt_Var_Id, @Mem1_Var_Id, @Mem2_Var_Id, @Mem3_Var_Id,
               @Mem4_Var_Id, @Mem5_Var_Id, @Mem6_Var_Id, @Mem7_Var_Id, @Mem8_Var_Id)
      SELECT @Calc_Id = Scope_Identity()
      IF @Calc_Id IS NULL
 	 BEGIN
 	       UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
 	       RETURN(1)
 	 END
    END
  ELSE
    --
    -- Update the existing calculation.
    --
    UPDATE Calcs
      SET Calculation = @Calculation,
          Rslt_Var_Id = @Rslt_Var_Id,
          Mem1_Var_Id = @Mem1_Var_Id,
          Mem2_Var_Id = @Mem2_Var_Id,
          Mem3_Var_Id = @Mem3_Var_Id,
          Mem4_Var_Id = @Mem4_Var_Id,
          Mem5_Var_Id = @Mem5_Var_Id,
          Mem6_Var_Id = @Mem6_Var_Id,
          Mem7_Var_Id = @Mem7_Var_Id,
          Mem8_Var_Id = @Mem8_Var_Id
      WHERE Calc_Id = @Calc_Id
  --
  -- Return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@Calc_Id) 
     WHERE Audit_Trail_Id = @Insert_Id
 RETURN(0)
