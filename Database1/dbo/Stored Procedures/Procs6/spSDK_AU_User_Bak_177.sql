CREATE procedure [dbo].[spSDK_AU_User_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@Description nvarchar(255) ,
@IsActive bit ,
@IsRole bit ,
@MixedModeLogin bit ,
@RoleBasedSecurity bit ,
@SSOUserId varchar(100) = null,
@SystemUser tinyint ,
@Username nvarchar(30) ,
@ViewId int ,
@WindowsUserInfo varchar(200) 
AS
DECLARE @Password  	  	  	 Varchar(100)
DECLARE @ViewDesc 	  	  	 Varchar(100)
DECLARE @ReturnMessages TABLE(msg VarChar(100))
DECLARE @OldUserName Varchar(30)
DECLARE @UseSSO varchar(10)
DECLARE @DBVersion varchar(100)
DECLARE @Pre60Server bit
SET 	 @ViewDesc = Null
EXEC dbo.spSupport_VerifyDB_PDBVersion  '00013.00000.00000.00000' , @Pre60Server OUTPUT
If (@SystemUser = 1)
 	 Begin
 	  	 SELECT 'Adding System Users is not supported'
 	  	 RETURN(-100)
 	 End
IF @ViewId Is Not Null
BEGIN
 	 SELECT @ViewDesc = View_Desc FROM Views  WHERE View_Id = @ViewId
 	 IF @ViewDesc Is NULL
 	 BEGIN
 	  	 SELECT 'View not found for update'
 	  	 RETURN(-100)
 	 END
END
 	 
IF @Id is Not null
BEGIN
 	 IF Not Exists(SELECT 1 FROM Users WHERE User_Id = @Id)
 	 BEGIN
 	  	 SELECT 'User not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @Password = a.Password,
 	  	  	  	  @OldUserName = a.Username 
 	 FROM Users a
 	 WHERE User_Id = @Id
 	 If @OldUserName <> @UserName
 	 Begin
 	  	 SELECT 'User Name is not updateable'
 	  	 RETURN(-100)
 	 END
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Users WHERE Username = @UserName)
 	 BEGIN
 	  	 SELECT 'User already exists cannot add'
 	  	 RETURN(-100)
 	 END
 	 /* DEFAULT For Now */
 	 SET @Password = CONVERT(VarChar(25),getdate())
END
Select @UseSSO = '0'
If (@SSOUserId Is Not Null)
 	 Select @UseSSO = '1'
If (@Pre60Server = 1)
 	 Begin
 	  	 INSERT INTO @ReturnMessages(msg)
 	  	  	 EXECUTE spEM_IEImportUsers @UserName,@Description,@Password,@IsActive,@ViewDesc,@WindowsUserInfo,@RoleBasedSecurity,@MixedModeLogin,@AppUserId
 	 End
Else
 	 Begin
 	  	 INSERT INTO @ReturnMessages(msg)
 	  	  	 EXECUTE spEM_IEImportUsers @UserName,@Description,@Password,@IsActive,@ViewDesc,@WindowsUserInfo,@RoleBasedSecurity,@MixedModeLogin,@AppUserId,@SSOUserId,@UseSSO
 	 End
 	  	  	  	 
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
IF @Id is Null
 	 SELECT @Id = USER_ID FROM Users WHERE Username = @UserName
RETURN(1)
