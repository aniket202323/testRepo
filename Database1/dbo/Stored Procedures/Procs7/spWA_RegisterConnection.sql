CREATE PROCEDURE [dbo].[spWA_RegisterConnection]
  @UserId INT
, @Host_Name nvarchar(50)= 'localhost'
AS
IF @UserId IS NULL
  RETURN
DECLARE @LangId INT
DECLARE @LCID INT
Declare @ValidUser Int, @ValidLanguage int
Declare @ErrMsg nvarchar(150)
SELECT @LCID = Localid , @LangId = Language_Id
FROM Client_Connections
WHERE HostName = @Host_Name And Process_Id = -999
IF @LangId IS NULL
BEGIN
  Select @LangId = Convert(int, value) from Site_Parameters where  Parm_Id = 8
END
IF @LangId IS NULL
BEGIN
  SET @LangId = 0
END
----Cleanup Invalid Spids
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
    Set @ErrMsg = 'SP: Cannot Register Connection Because User Id ' + Cast(@UserId As nvarchar(10))  + ' Is Invalid'
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
--Cleanup A Previous Connection With The Same Info
--DELETE FROM User_Connections
--WHERE Spid = @@Spid AND [User_Id] = @UserId AND Language_Id = @LangId
IF NOT EXISTS(SELECT 1 FROM User_Connections WHERE Spid = @@Spid and User_Id = @UserId and Language_Id = @LangId )
BEGIN
      DELETE FROM User_Connections WHERE Spid = @@Spid
      INSERT INTO User_Connections(SPID, [User_Id], Language_Id)VALUES(@@SPID, @UserId, @LangId)
END
