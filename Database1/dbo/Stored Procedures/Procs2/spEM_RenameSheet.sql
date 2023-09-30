CREATE PROCEDURE dbo.spEM_RenameSheet
  @Sheet_Id   int,
  @Sheet_Desc nvarchar(50),
  @User_Id int
  AS
  --
  -- Return Codes: (0) Success
  --               (1) Sheet is active.
  --               (2) Sheet not found.
  --
  DECLARE @Insert_Id integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameSheet',
                Convert(nVarChar(10),@Sheet_Id) + ','  + 
                @Sheet_Desc + ','  + 
 	    Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
 	 If (@@Options & 512) = 0
 	  	 Update Sheets Set Sheet_Desc_Global = @Sheet_Desc  Where Sheet_Id = @Sheet_Id
 	 Else
 	  	 Update Sheets Set Sheet_Desc_Local = @Sheet_Desc Where Sheet_Id = @Sheet_Id
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
