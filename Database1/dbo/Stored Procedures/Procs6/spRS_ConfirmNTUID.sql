CREATE PROCEDURE dbo.spRS_ConfirmNTUID
@UserName varchar(100)
 AS
Declare @Template_Id int -- needs to be an output parameter
Declare @User_Id int -- needs to be an output parameter
Declare @User_Name varchar(20)
Declare @Rows int
Declare @Password varchar(20)
Select @Template_Id = Report_Tree_Template_Id, @User_Id = RTU.User_Id, @User_Name = U.Username, @Password = U.Password
From Report_Tree_Users RTU
Left Join Users U on U.User_Id = RTU.User_Id
Where NTUserID = @UserName
Select @Rows = @@Rowcount
If @Template_Id Is Null
  Select 0 'Template_Id', 0 'User_Id'
Else
  Begin
    If @Rows > 1
      Select 0 'Template_Id', 0 'User_Id'
    Else
      Select @Template_Id 'Template_Id', @User_Id 'User_Id', @User_Name 'Username', @Password 'Password'
  End
