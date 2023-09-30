/* This sp is called by dbo.spBatch_GetSingleUDEvent parameters need to stay in sync*/
/* This sp is called by dbo.spBatch_GetSingleVariable parameters need to stay in sync*/
CREATE PROCEDURE dbo.spEM_CreateVariable
  @Description nvarchar(50),
  @PU_Id       int,
  @PUG_Id      int,
  @PUG_Order   int,
  @User_Id int,
  @Var_Id      int OUTPUT AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create variable.
  --
  -- Begin a transaction.
  --
  DECLARE @Insert_Id Int,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateVariable',
                 @Description + ',' + convert(nVarChar(10),@PU_Id) + ','  + Convert(nVarChar(10), @PUG_Id) + ','  + Convert(nVarChar(10), @PUG_Order) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
BEGIN TRANSACTION
  --
  -- Create a new variable.
  --
 	 INSERT INTO Variables(Var_Desc,PU_Id,Data_Type_Id,DS_Id,PUG_Id,PUG_Order,Var_Precision,Force_Sign_Entry,TF_Reset,Tot_Factor,Sampling_Window)
 	  	 VALUES(@Description,@PU_Id,2,4,@PUG_Id,@PUG_Order,2,0,0,Null,0)
  --
  -- Determine the id of the newly created variable.
  --
  SELECT @Var_Id = Var_Id From Variables where Var_Desc = @Description and pu_Id = @PU_Id
  IF @Var_Id IS NULL or @Var_Id != IDENT_CURRENT('Variables')
    BEGIN
 	  	  	 Select @Var_Id = Null
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Var_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
