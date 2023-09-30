Create Procedure dbo.spDBR_Get_Import_Token
@UserID int,
@Node varchar(50)
AS
declare @user varchar(50)
declare @encryptedpassword varchar(50)
declare @pwd varchar(50)
execute spServer_CmnGetParameter 19,@UserID, @Node, @user output
execute spServer_CmnGetParameter 20,@UserID, @Node, @encryptedpassword output
EXEC spCmn_Encryption @EncryptedPassword,'EncrYptoR',20,0,@pwd output
select @user as username, @pwd as password, @encryptedpassword as encrypted
