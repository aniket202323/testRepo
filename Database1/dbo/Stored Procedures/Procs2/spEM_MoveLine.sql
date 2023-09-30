CREATE PROCEDURE dbo.spEM_MoveLine
  @PL_Id int,
  @Dept_Id int,
  @User_Id int
  AS
  --
  -- Begin a transaction.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_MoveLine',
                 convert(nVarChar(10),@PL_Id) + ','  + Convert(nVarChar(10), @Dept_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  UPDATE Prod_Lines SET Dept_Id = @Dept_Id WHERE PL_Id = @PL_Id
  COMMIT TRANSACTION
  --
  -- Commit the transaction.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
