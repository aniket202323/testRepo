﻿CREATE PROCEDURE [dbo].[spDBR_RegisterConnection]
  @UserId INT
AS
IF @UserId IS NULL
  RETURN
DECLARE @LangId INT
Declare @ValidUser Int, @ValidLanguage int
Declare @ErrMsg VarChar(150)
SELECT @LangId = Value
FROM user_parameters
WHERE parm_id = 8 AND [User_Id] = @UserId
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
  Select @LangId = Convert(int, value) from Site_Parameters where  Parm_Id = 8
END
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
select @ValidLanguage = Count(*)
From Languages
where [Language_Id] = @LangId
if (@ValidLanguage = 0)
  Begin
    Return
  End
IF NOT EXISTS(SELECT 1 FROM User_Connections WHERE Spid = @@Spid and User_Id = @UserId and Language_Id = @LangId )
BEGIN
      DELETE FROM User_Connections WHERE Spid = @@Spid
      INSERT INTO User_Connections(SPID, [User_Id], Language_Id)VALUES(@@SPID, @UserId, @LangId)
END
