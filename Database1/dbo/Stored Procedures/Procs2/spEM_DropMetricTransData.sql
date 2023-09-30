CREATE PROCEDURE dbo.spEM_DropMetricTransData
  @Trans_Id int,
  @TimeStamp DateTime,
  @User_Id   int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropMetricTransData',
                 convert(nVarChar(10),@Trans_Id)  + ','  + convert(nVarChar(25),@TimeStamp)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  -- Begin a transaction.
  --
  DELETE FROM Trans_Metric_Properties WHERE Trans_Id = @Trans_Id and Effective_Date = @TimeStamp
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
