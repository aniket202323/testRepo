CREATE PROCEDURE dbo.spEM_DropScheduleStatus
  @PP_Status_Id int,
  @User_Id int
 AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Begin a transaction.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropScheduleStatus',
                 convert(nVarChar(10),@PP_Status_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  --
  -- Delete the schedule status.
  --
  DELETE FROM Production_Plan_Statuses WHERE PP_Status_Id = @PP_Status_Id
  --
  -- Commit our transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
