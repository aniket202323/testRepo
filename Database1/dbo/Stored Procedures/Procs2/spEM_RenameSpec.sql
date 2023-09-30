CREATE PROCEDURE dbo.spEM_RenameSpec
  @Spec_Id   int,
  @Spec_Desc nvarchar(50),
  @User_Id    int
  AS
  DECLARE @Insert_Id integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameSpec',
                Convert(nVarChar(10),@Spec_Id) + ','  + 
                @Spec_Desc + ','  + 
                Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
 	   If (@@Options & 512) = 0
 	  	 Update Specifications Set Spec_Desc_Global = @Spec_Desc Where Spec_Id = @Spec_Id
     Else
 	  	 Update Specifications Set Spec_Desc_Local = @Spec_Desc Where Spec_Id = @Spec_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
