CREATE PROCEDURE dbo.spEM_RenameProdDesc
  @Prod_Id   int,
  @Prod_Desc nvarchar(50),
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  DECLARE @Insert_Id integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameProdDesc',
                Convert(nVarChar(10),@Prod_Id) + ','  + 
                @Prod_Desc+ ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  If (@@Options & 512) = 0
 	 Update Products_Base  Set Prod_Desc_Global = @Prod_Desc Where Prod_Id = @Prod_Id
 Else
 	 Update Products_Base Set Prod_Desc = @Prod_Desc Where Prod_Id = @Prod_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
