--***********************************************************************************************
--Note:  A parallel version of this stored procedure exists and is named spCSS_LoginUser.
--       It does not have the UseMixedModeLogin input paramater and is for 215.x client and prior.  
--       Any changes made to this stored procedure may need to be made to spCSS_LoginUser.
--***********************************************************************************************
CREATE PROCEDURE dbo.spCSS_LoginUser3
@UserName nvarchar(50),
@PassWord nvarchar(50),
@UseMixedModeLogin int,
@LoggedIn int OUTPUT,
@User_Id int OUTPUT,
@Role_Based_Security bit OUTPUT
AS
Declare @WindowsInfo nvarchar(100),
        @UsersMixedMode int
-- decrypt logic
Declare @textlen int = len(@PassWord),@loopvar int = 1, @decryptstring varchar(max)= '',@asciival int
Declare @pwdlen int = REVERSE(LEFT(REVERSE(@PassWord),patindex('%/%',REVERSE(@PassWord)) -1))
While @loopvar <= @pwdlen
Begin
----Select Substring(@text,@loopvar,1) as 'substring '
SET @asciival = ASCII(Substring(@PassWord,@loopvar,1)) - @pwdlen
--Select @asciival as 'Asciival'
 --Select Char(@asciival)
 SET @decryptstring = @decryptstring + Char(@asciival)
 --Select @decryptstring
 SET @loopvar = @loopvar + 1
END
SET @Password = @decryptstring
--ENd of Decrypt logic
--Select @Password
Select @User_Id = NULL
Select @User_Id = User_Id, @Role_Based_Security = Role_Based_Security, @UsersMixedMode = Mixed_Mode_Login, @WindowsInfo = Coalesce(WindowsUserInfo,'')
  From Users
  Where UserName = @UserName and Active = 1 and Is_Role = 0 and
       ((Password = @Password) or (((@Password Is Null) or (@Password = '')) and (Password Is Null)))
If @UseMixedModeLogin = 0
  Begin
    If @UsersMixedMode = 0 and Len(@WindowsInfo) > 0
      Begin
        --Failed log in because Mixed_Mode was required to be True (1)
        Select @User_Id = Null
      End
  End
--Null User_Id Indicates Unsuccessful Login
If @User_Id Is Null 
  Select @LoggedIn = 0
Else
  Select @LoggedIn = 1
