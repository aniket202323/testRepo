CREATE PROCEDURE dbo.spEM_DropEmailGroup
  @Group_Id int,
  @User_Id int
 AS
  --
  -- Return Codes: (0) Success
  --               (1) Sheet is active.
  --               (2) Sheet not found.
  --
  DECLARE @Insert_Id int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropEmailGroup',
                 convert(nVarChar(10),@Group_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
   Delete From Email_Groups_Data WHERE EG_Id  = @Group_Id
   Delete From Email_Groups Where EG_Id  = @Group_Id
   Update Alarm_Template_Var_Data Set EG_Id = NULL Where EG_Id = @Group_Id
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
