CREATE PROCEDURE dbo.spEM_ActivateDataSource
  @DS_Id  int,
  @New_State bit,
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
  DECLARE @Old_State bit, 
 	       @Var_Count int,
 	       @Insert_Id integer 
 Insert into Audit_Trail(Application_id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,1,'spEM_ActivateDataSource',  convert(nVarChar(10),@DS_Id) + ','  + Convert(nVarChar(1), @New_State) + ','  + Convert(nVarChar(10), @User_id),dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  --
  -- Make sure we don't dactivate a DataSource with  variables assigned.
IF @New_State = 0 
BEGIN
 	 IF((Select Count(*)   From Variables Where Ds_Id =  @DS_Id Or Write_Group_DS_Id =  @DS_Id) > 0)  or  (@Ds_Id = 4)
 	     BEGIN
 	              Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 107 where Audit_Trail_Id = @Insert_Id
 	      	 RETURN 107
 	     END
END
  BEGIN TRANSACTION
--
  -- Make sure we don't chage the activation status of a sheet that has already changed.
  --
  SELECT @Old_State = Active FROM Data_Source WHERE DS_Id = @DS_Id
  IF @Old_State = @New_State
    BEGIN
      ROLLBACK TRANSACTION
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  --
  -- Chage the activation status of the sheet.
  --
  UPDATE Data_Source SET Active = @New_State WHERE DS_Id = @DS_Id
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
RETURN(0)
