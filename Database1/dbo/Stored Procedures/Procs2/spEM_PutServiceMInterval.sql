CREATE PROCEDURE dbo.spEM_PutServiceMInterval
  @Service_Id   int,
  @Monitor_Interval int,
  @User_Id int
 AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutServiceMInterval',
                Convert(nVarChar(10),@Service_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Monitor_Interval) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success.
  --
  -- Update the monitor Interval
  --
  UPDATE CXS_Service SET Monitor_Interval  = @Monitor_Interval WHERE Service_Id = @Service_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
