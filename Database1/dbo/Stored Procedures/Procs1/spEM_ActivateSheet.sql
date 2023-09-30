CREATE PROCEDURE dbo.spEM_ActivateSheet
  @Sheet_Id  int,
  @New_State int,
  @User_Id        int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: State already changed.
  --   2 = Error: Can't activate sheet with no variables assigned.
  --
  -- Declare local variables and begin a transaction.
  --
  DECLARE @Old_State int, 
 	       @Var_Count int,
 	       @Insert_Id integer 
 Insert into Audit_Trail(Application_id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,1,'spEM_ActivateSheet',  convert(nVarChar(10),@Sheet_Id) + ','  + Convert(nVarChar(1), @New_State) + ','  + Convert(nVarChar(10), @User_id),dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  --
  -- Make sure we don't activate a sheet with no variables assigned.
  --
  IF @New_State = 1
/*
    BEGIN
      SELECT @Var_Count = COUNT(Var_Id) FROM Sheet_Variables WHERE Sheet_Id = @Sheet_Id
      IF @Var_Count = 0
        BEGIN
          ROLLBACK TRANSACTION
         Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 2 where Audit_Trail_Id = @Insert_Id
         RETURN(2)
        END
    END
*/  
--
  -- Make sure we don't chage the activation status of a sheet that has already changed.
  --
  SELECT @Old_State = Is_Active FROM Sheets WHERE Sheet_Id = @Sheet_Id
  IF @Old_State = @New_State
    BEGIN
      ROLLBACK TRANSACTION
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  --
  -- Chage the activation status of the sheet.
  --
  UPDATE Sheets SET Is_Active = @New_State WHERE Sheet_Id = @Sheet_Id
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
RETURN(0)
