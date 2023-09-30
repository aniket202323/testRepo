CREATE PROCEDURE dbo.spEM_DropDataSource
  @Data_Source_Id int,
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
 	 VALUES (1,@User_Id,'spEM_DropDataSource',
                 convert(nVarChar(10),@Data_Source_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  --
  -- Delete the data type and its phrases.
  --
  UPDATE Variables_Base set DS_Id = 4 Where DS_Id = @Data_Source_Id
  UPDATE Variables_Base set Output_DS_Id = 4 Where Output_DS_Id = @Data_Source_Id
 	 DELETE From Data_Source_XRef Where DS_Id = @Data_Source_Id
  DELETE FROM Data_Source WHERE DS_Id = @Data_Source_Id
  --
  -- Commit our transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
