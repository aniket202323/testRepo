CREATE PROCEDURE dbo.spRS_ConfirmUID
@UserName varchar(50),
@PW  varchar(50)
As
Declare @Template_Id int
Declare @User_Id int
Declare @UN varchar(50)
SELECT @User_Id = 0
If @Pw = '' or @Pw Is Null
  Begin
    SELECT @User_Id = User_Id
      FROM USERS
      WHERE Username = @Username AND
      (Password Is Null or Password = '')
  End
Else
  Begin
    SELECT @User_Id = User_Id
     FROM USERS
     WHERE Username = @Username AND
     Password = @PW
  End
IF @User_Id = 0 	 -- there is no such user
 	 Begin
 	   Select 0 'User_Id', 0 'Template_Id', 'Unknown' 'Username'
 	   Return (1)
 	 End
Else
 	 Begin
 	   Select @Template_Id = Report_Tree_Template_Id, @UN = U.Username
 	     From Report_Tree_Users RTU
 	     Left Join Users U on RTU.User_Id  = U.User_Id
 	     Where RTU.User_Id = @User_Id
 	     If @Template_Id is Null
 	        Begin
 	          --Select 0 'User_Id', 0 'Template_Id', 'Unknown' 'Username'
 	  	  	  Select @User_Id 'User_Id', 0 'Template_Id', @UserName 'UserName'
 	          Return (2)
 	        End
 	     Else
 	        Select @User_Id 'User_Id', @Template_Id 'Template_Id', @UN 'Username'
 	        Return (0)
 	 End
