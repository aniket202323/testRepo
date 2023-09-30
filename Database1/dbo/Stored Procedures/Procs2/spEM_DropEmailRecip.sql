CREATE PROCEDURE dbo.spEM_DropEmailRecip
  @Recip_Id int,
  @User_Id int
 AS
  --
  -- Return Codes: (0) Success
  --               (1) Sheet is active.
  --               (2) Sheet not found.
  --
  DECLARE @Insert_Id int,
 	       @Is_Active int,
 	       @SId          int,
 	       @RsltOn     DateTime
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropEmailRecip',
                 convert(nVarChar(10),@Recip_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
   Delete From Email_Groups_Data WHERE ER_Id  = @Recip_Id
   Delete From Email_Recipients Where ER_Id  = @Recip_Id
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
