Create Procedure dbo.spEMSEC_PutReasonShortcut
  @PUId 	  	  	  	 int,
  @AppId 	  	  	 int,
  @SPUId 	  	  	 int,
  @ShortcutName 	  	 nVarChar(25),
  @Amount 	  	  	 real,
  @RLevel1 	  	  	 nVarChar(100),
  @RLevel2 	  	  	 nVarChar(100),
  @RLevel3 	  	  	 nVarChar(100),
  @RLevel4 	  	  	 nVarChar(100),
  @User_Id 	  	  	 int,
  @RS_Id 	  	  	 int 	  	 OUTPUT
AS
IF @SPUId Is NULL AND @RS_Id IS NOT NULL AND @PUId IS NULL
BEGIN
 	 DELETE Reason_Shortcuts WHERE RS_Id = @RS_Id
END
ELSE
BEGIN
 	 EXECUTE spEM_PutReasonShortcut   
 	  	  	 @PUId,
 	  	  	 @RS_Id,
 	  	  	 @AppId,
 	  	  	 @SPUId,
 	  	  	 @ShortcutName,
 	  	  	 @Amount,
 	  	  	 @RLevel1,
 	  	  	 @RLevel2,
 	  	  	 @RLevel3,
 	  	  	 @RLevel4,
 	  	  	 @User_Id
 	 SELECT @RS_Id = RS_Id FROM Reason_Shortcuts WHERE Shortcut_Name = @ShortcutName and PU_Id = @PUId AND App_Id = @AppId
END
