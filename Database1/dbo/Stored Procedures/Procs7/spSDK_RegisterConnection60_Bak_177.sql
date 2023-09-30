CREATE PROCEDURE [dbo].[spSDK_RegisterConnection60_Bak_177]
  @UserId INT
AS
IF @UserId IS NULL
  RETURN
DECLARE @LangId INT
Declare @ValidUser Int
Declare @ErrMsg VarChar(150)
SELECT @LangId = NULL
SELECT @LangId = Value
FROM user_parameters
WHERE parm_id = 8 AND [User_Id] = @UserId
-- TJN 10/4/2011 commented out the block below per Dave Haines request
--Cleanup Invalid Spids
--DELETE FROM User_Connections
--WHERE spid in
--(SELECT UC.spid
--FROM User_Connections uc
--LEFT OUTER JOIN Master..Sysprocesses sp ON sp.spid = uc.spid
--WHERE sp.spid is null)
--select * from master..sysprocesses
--Default to English
IF @LangId IS NULL
BEGIN
  SET @LangId = 0
END
Select @ValidUser = Count(*)
From Users
Where [User_Id] = @UserId
If @ValidUser = 0
  Begin
    Set @ErrMsg = 'SP: Cannot Register Connection Because User Id ' + Cast(@UserId As VarChar(10))  + ' Is Invalid'
    Raiserror(@ErrMsg, 16, 1)
    Return
  End
IF NOT EXISTS(SELECT 1 FROM User_Connections WHERE Spid = @@Spid and User_Id = @UserId and Language_Id = @LangId )
BEGIN
 	 DELETE FROM User_Connections WHERE Spid = @@Spid
 	 INSERT INTO User_Connections(SPID, [User_Id], Language_Id)VALUES(@@SPID, @UserId, @LangId)
END
