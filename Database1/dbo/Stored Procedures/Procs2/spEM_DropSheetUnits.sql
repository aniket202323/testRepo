CREATE PROCEDURE dbo.spEM_DropSheetUnits
  @Sheet_Id int,
  @User_Id int
 AS
  --
  -- Return Codes: (0) Success
  --               (1) Sheet is active.
  --               (2) Sheet not found.
  --
  DECLARE @Insert_Id int,@ST Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropSheetUnits',
                 convert(nVarChar(10),@Sheet_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 Select @ST = Sheet_Type From Sheets where  Sheet_Id = @Sheet_Id
BEGIN TRANSACTION
  If @ST IN( 10 , 14,8,15,11,30)
   	 Delete From Sheet_Unit Where Sheet_Id = @Sheet_Id
  Else If @ST  = 17
 	 Delete From Sheet_Paths Where Sheet_Id = @Sheet_Id
COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
