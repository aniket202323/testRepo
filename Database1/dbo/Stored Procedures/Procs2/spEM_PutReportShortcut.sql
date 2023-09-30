Create Procedure dbo.spEM_PutReportShortcut
  @PU_Id          int,
  @RS_Id          int,
  @App_Id         int,
  @Report_Name   nvarchar(25),
  @Document_Name nVarChar(100),
  @User_Id int
AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutReportShortcut',
                Convert(nVarChar(10),@PU_Id) + ','  + 
 	  	 Convert(nVarChar(10),@RS_Id) + ','  + 
 	  	 Convert(nVarChar(10),@App_Id) + ','  + 
 	  	 LTRIM(RTRIM(@Report_Name)) + ','  + 
 	  	 LTRIM(RTRIM(@Document_Name)) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- insert - IF RsId is null
  -- update - IF RsId not null and TnId not null
  -- delete - IF RsId not null and TnId is null 
  --
  -- Begin a transaction.
  --
  BEGIN TRANSACTION
  --
  -- 
  --
IF @RS_Id IS NULL 
  INSERT Report_Shortcuts (App_Id,
                           PU_Id,
                           Report_Name,
                           Document_Name)
                    Values(@App_Id,
                           @PU_Id,
                           @Report_Name,
                           @Document_Name)
ELSE IF @Report_Name <> ''
        UPDATE Report_Shortcuts 
         SET App_Id = @App_Id,
             PU_Id = @PU_Id,
             Report_Name = @Report_Name,
             Document_Name = @Document_Name
         WHERE Report_Shortcut_Id = @RS_Id
      ELSE
        DELETE Report_Shortcuts WHERE Report_Shortcut_Id = @RS_Id
COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
RETURN(0)
