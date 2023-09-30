CREATE PROCEDURE dbo.spEM_IEImportUsers
@UserName  	  	  	 nVarChar(100),
@User_Desc  	  	  	 nVarChar(100),
@Password  	  	  	 nVarChar(100),
@Active_Desc 	  	 nVarChar(100),
@View_Desc 	  	  	 nVarChar(100),
@WindowsLoginInfo 	 nVarChar(200),
@RoleBased_Desc nVarChar(100),
@MixedMode_Desc nVarChar(100),
@SSOName 	  	  	  	 nVarChar(100),
@UseSSO 	  	  	  	  	 nVarChar(10),
@In_User_Id  	  	 int
As
Declare @Active_Id 	 bit,
 	  	 @View_Id  	 int,
 	  	 @System 	  	 bit,
 	  	 @User_Id 	 Int,
    @Role_Based_Security bit,
    @Mixed_Mode_Login bit,
    @UseSSOId 	  	 bit
/* Initialization */
Select  @Active_Id = Null,
 	 @View_Id = Null,
 	 @User_Id = Null,
  @Role_Based_Security = Null,
  @Mixed_Mode_Login = Null
/* Get Active id */
If Upper(RTrim(LTrim(@Active_Desc))) = 'YES' Or Upper(RTrim(LTrim(@Active_Desc))) = 'TRUE' Or RTrim(LTrim(@Active_Desc)) = '1'
     Select @Active_Id = 1
Else
     Select @Active_Id = 0
If Upper(RTrim(LTrim(@UseSSO))) = 'YES' Or Upper(RTrim(LTrim(@UseSSO))) = 'TRUE' Or RTrim(LTrim(@UseSSO)) = '1'
     Select @UseSSOId = 1
Else
     Select @UseSSOId = 0
/* Get Role-Based id */
If Upper(RTrim(LTrim(@RoleBased_Desc))) = 'YES' Or Upper(RTrim(LTrim(@RoleBased_Desc))) = 'TRUE' Or RTrim(LTrim(@RoleBased_Desc)) = '1'
     Select @Role_Based_Security = 1
Else
     Select @Role_Based_Security = 0
/* Get Mixed-Mode id */
If Upper(RTrim(LTrim(@MixedMode_Desc))) = 'YES' Or Upper(RTrim(LTrim(@MixedMode_Desc))) = 'TRUE' Or RTrim(LTrim(@MixedMode_Desc)) = '1'
     Select @Mixed_Mode_Login = 1
Else
     Select @Mixed_Mode_Login = 0
/* Get Default View */
Select @View_Id = View_Id
From Views
Where View_Desc = RTrim(LTrim(@View_Desc))
If @View_Desc Is Not Null And RTrim(LTrim(@View_Desc)) <> '' And @View_Id Is Null
Begin
    Select 'Failed - View Not Found'
    Return(-100)
End
SET @SSOName =  RTrim(LTrim(@SSOName))
IF  @SSOName = '' Set @SSOName = Null
/* Check to see if user exists */
Select 	 @User_Id  	 = User_Id,
 	 @User_Desc  	 = IsNull(@User_Desc, User_Desc),
 	 @Password  	 = IsNull(@Password, Password),
 	 @Active_Id 	 = IsNull(@Active_Id, Active),
 	 @View_Id 	 = IsNull(@View_Id, View_Id),
 	 @System = System,
 	 @WindowsLoginInfo = IsNull(@WindowsLoginInfo,WindowsUserInfo),
  @Role_Based_Security = IsNull(@Role_Based_Security,Role_Based_Security),
  @Mixed_Mode_Login = IsNull(@Mixed_Mode_Login,Mixed_Mode_Login)
From Users
Where Username = @Username
If @Active_Id = 0 and @User_Id = @In_User_Id 
 	 Begin
 	  	   Select 'Failed - can set your own account to inactive'
 	  	   Return (-100)
 	 End
/* If doesn't exist then create */
If @User_Id Is Null
 	 Execute spEM_CreateUser  @Username,@In_User_Id,@User_Id  OUTPUT,@User_Desc
/* Update configuration */
If @User_Id Is Not Null
Begin
 	 If @System = 1
 	  	 Begin
 	  	   Select 'Failed - can not update system users'
 	  	   Return (-100)
 	  	 End
    /* Verify data against existing data */
    Select 	 @User_Id  	 = IsNull(@User_Id, User_Id),
 	  	 @User_Desc  	 = IsNull(@User_Desc, User_Desc),
 	  	 @Password  	 = IsNull(@Password, Password),
 	  	 @Active_Id 	 = IsNull(@Active_Id, Active),
 	  	 @View_Id 	 = IsNull(@View_Id, View_Id),
    @Role_Based_Security = IsNull(@Role_Based_Security,Role_Based_Security),
    @Mixed_Mode_Login = IsNull(@Mixed_Mode_Login,Mixed_Mode_Login)
    From Users
    Where User_Id = @User_Id
 	 Execute spEM_PutUserData @User_Id,@User_Desc,@Password,@Active_Id,@View_Id,@WindowsLoginInfo,@In_User_Id,@Role_Based_Security,@Mixed_Mode_Login,@SSOName,@UseSSOId,0
End
Else
Begin
 	 Select 'Failed - unable to create user'
 	 Return (-100)
 	 
End
/* Commit and End */
Return(0)
