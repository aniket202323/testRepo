CREATE PROCEDURE dbo.spEM_CreatePHN
  @Alias_Desc nvarchar(255),
  @User_Id int,
  @PHN_Id   int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create PI home node.
  --
 DECLARE @Insert_Id integer 
 Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreatePHN',
                 @Alias_Desc + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
 DECLARE @HistCount Int
Select @HistCount = count(*) From Historians Where Hist_Type_Id <> 7
 INSERT INTO Historians(Hist_ServerName, Hist_OS_Id,Hist_Type_Id,Hist_Default,Alias,Is_Active) VALUES(@Alias_Desc, 2,1,0,@Alias_Desc,1)
  SELECT @PHN_Id = Scope_Identity()
  IF @PHN_Id IS NULL
 	 BEGIN
 	    Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	    RETURN(1)
 	 END
 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@PHN_Id) where Audit_Trail_Id = @Insert_Id
  If @HistCount = 0
 	  EXECUTE spEM_PHNDefault @PHN_Id,@User_Id
  RETURN(0)
