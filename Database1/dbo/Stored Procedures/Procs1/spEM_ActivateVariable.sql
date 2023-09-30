CREATE PROCEDURE dbo.spEM_ActivateVariable
  @VarId  int,
  @NewState int,
  @User_Id        int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: State already changed.
  --
  -- Declare local variables and begin a transaction.
  --
  DECLARE @OldState int, 
 	       @Var_Count int,
 	       @Insert_Id integer 
 Insert into Audit_Trail(Application_id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,1,'spEM_ActivateVariable',  convert(nVarChar(10),@VarId) + ','  + Convert(nVarChar(1), @NewState) + ','  + Convert(nVarChar(10), @User_id),dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  --
  -- Make sure we don't activate a Variable with no variables assigned.
  --
--
  -- Make sure we don't chage the activation status of a Variable that has already changed.
  --
  SELECT @OldState = Is_Active FROM Variables WHERE Var_Id = @VarId
  IF @OldState = @NewState
    BEGIN
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  --
  -- Chage the activation status of the Variable.
  --
  UPDATE Variables_Base SET Is_Active = @NewState WHERE Var_Id = @VarId
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
RETURN(0)
