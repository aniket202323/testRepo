CREATE PROCEDURE dbo.spEM_DropDataType
  @Data_Type_Id int,
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
 	 VALUES (1,@User_Id,'spEM_DropDataType',
                 convert(nVarChar(10),@Data_Type_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  --
  -- Delete the data type and its phrases.
  --
  DELETE FROM Phrase WHERE Data_Type_Id = @Data_Type_Id
  DELETE FROM Data_Type WHERE Data_Type_Id = @Data_Type_Id
  --
  -- Commit our transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
