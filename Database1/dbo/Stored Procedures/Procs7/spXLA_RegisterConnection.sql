CREATE PROCEDURE [dbo].[spXLA_RegisterConnection]
  @UserId Int
, @LangId Int
AS
Declare @ValidUser Int, @ValidLanguage int
Declare @ErrMsg VarChar(150)
IF @UserId IS NULL
  RETURN
--Default to English
IF @LangId IS NULL
BEGIN
  Select @LangId = Convert(int, value) from Site_Parameters where  Parm_Id = 8
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
