CREATE PROCEDURE dbo.spEM_DropSheetGroup
  @SheetGrp_Id int,
  @User_Id   int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropSheetGroup',
                 convert(nVarChar(10),@SheetGrp_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Begin a transaction.
  --
  -- Do not allow drop or default group 
 If @SheetGrp_Id = 1
   Return(1)
 BEGIN TRANSACTION
  --
  -- 
   UPDATE Sheets SET Sheet_Group_Id = 1 WHERE Sheet_Group_Id = @SheetGrp_Id 
   DELETE FROM Sheet_Groups WHERE Sheet_Group_Id = @SheetGrp_Id
  --
  -- Commit our transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
