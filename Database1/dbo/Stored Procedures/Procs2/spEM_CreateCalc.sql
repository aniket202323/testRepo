Create Procedure dbo.spEM_CreateCalc
  @Var_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Variable not found.
  --
  -- Declare local variables.
  --
  DECLARE @DS_Id int,
 	       @Insert_Id integer 
 Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateCalc',
                 convert(nVarChar(10),@Var_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
 --
  -- Begin a transaction.
  --
  BEGIN TRANSACTION
  --
  -- Determine the variable's data source. If the data source
  -- is already the Calc Engine, return success.
  --
  SELECT @DS_Id = DS_Id FROM Variables WHERE Var_Id = @Var_Id
  IF @DS_Id IS NULL
     BEGIN
 	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	  RETURN(1)
     END
  IF @DS_Id = 5 
     BEGIN
 	 -- already a calc (2 for logfile)
 	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 2 where Audit_Trail_Id = @Insert_Id
 	  RETURN(0)
     END
  --
  -- Convert the variable's data source to Calc Engine and update
  -- other fields.
  --
  UPDATE Variables_Base
    SET DS_Id = 5,
        DQ_Tag = NULL,
        Input_Tag = NULL,
        Sampling_Type = NULL,
        Sampling_Interval = NULL,
        Sampling_Offset = NULL,
        Tot_Factor = NULL
    WHERE Var_Id = @Var_Id
  --
  -- Insert the corresponding record into the Calcs table.
  --
  INSERT INTO Calcs(Rslt_Var_Id) VALUES(@Var_Id)
  --
  -- Commit our transaction and return success.
  --
  COMMIT TRANSACTION
 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
 RETURN(0)
