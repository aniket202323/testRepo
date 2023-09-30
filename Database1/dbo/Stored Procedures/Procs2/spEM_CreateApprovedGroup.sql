Create Procedure dbo.spEM_CreateApprovedGroup
  @ApprovedGroup_Desc      nvarchar(50),
  @User_Id int,
  @ApprovedGroup_Id        int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create characteristic.
  --
 DECLARE @Insert_Id integer 
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateApprovedGroup',
                 convert(nVarChar(10),@ApprovedGroup_Desc) + ','  +  Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
 BEGIN TRANSACTION
  INSERT INTO Transaction_Groups(Transaction_Grp_Desc) VALUES(@ApprovedGroup_Desc)
  SELECT @ApprovedGroup_Id = Scope_Identity()
  IF @ApprovedGroup_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  COMMIT TRANSACTION
 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@ApprovedGroup_Id) where Audit_Trail_Id = @Insert_Id
 RETURN(0)
