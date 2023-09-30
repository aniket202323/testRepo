-- spEM_IEImportSecurityRoles 't','t2','t','Read/Write','0',1
CREATE PROCEDURE dbo.spEM_IEImportSecurityRoles
@SecurityRole 	  	 nVarChar(100),
@SecurityRoleMember 	 nVarChar(200),
@SecurityGroupDesc 	 nVarChar(100),
@ALDesc 	  	  	 nVarChar(100),
@IsNTGroup 	  	 nVarChar(10),
@DomainName 	  	 nVarChar(100),
@InUserId 	  	 int
AS
Declare @Description  	  	 nVarChar(100),
 	 @SecurityRoleMemberId  	 int,
 	 @UserId 	  	  	 int,
 	 @RoleUserId 	  	  	 int,
 	 @Access_Level 	  	 int,
 	 @Security_Id 	  	 Int,
 	 @SecurityGroupId 	 Int,
 	 @IsRole 	  	  	 Int
/* Initialization */
Select  	 @SecurityRoleMemberId  	   = Null,
 	 @Access_Level = Null,
 	 @Security_Id  = Null,
 	 @UserId 	   = Null
/********************************/
/* Create/Update User Groups 	 */
/********************************/
Select @SecurityRole  	  	 = RTrim(LTrim(@SecurityRole))
Select @SecurityRoleMember  	 = RTrim(LTrim(@SecurityRoleMember))
Select @SecurityGroupDesc  	 = RTrim(LTrim(@SecurityGroupDesc))
Select @ALDesc  	  	  	 = RTrim(LTrim(@ALDesc))
Select @DomainName 	  	 = RTrim(LTrim(@DomainName))
If @SecurityRole = ''  	  	 Select @SecurityRole = Null
If @SecurityRoleMember = ''  	 Select @SecurityRoleMember = Null
If @SecurityGroupDesc = ''  	 Select @SecurityGroupDesc = Null
If @ALDesc = ''  	  	 Select @ALDesc = Null
If @DomainName = '' 	  	 Select @DomainName = Null
If @SecurityRole Is Null
BEGIN
 	 Select 'Failed - Security Role field is missing'
 	 Return (-100)
END
IF @IsNTGroup is null
BEGIN
 	 Select 'Failed - NT Group option not found'
 	 Return (-100)
END
IF @IsNTGroup Not IN('0','1')
BEGIN
 	 Select 'Failed - NT Group option not correct'
 	 Return (-100)
END
/******************************************************************************************/
/* Get User Role 	  	  	  	  	  	  	 */
/******************************************************************************************/
Select @UserId = User_Id,@IsRole = Is_Role
From Users
Where Username = @SecurityRole
If @UserId Is Not Null and @IsRole = 0
BEGIN
 	 Select 'Failed - User Name found with same Role Name'
 	 Return (-100)
END
If @UserId Is Null /* Create User Role */
BEGIN
 	 Execute spEM_CreateSecurityRole  @SecurityRole,@InUserId,@UserId  OUTPUT
END
IF @ALDesc is Null and @SecurityRoleMember Is Null and @DomainName Is Null and @SecurityGroupDesc Is Null
BEGIN
 	 RETURN  --Create Role Only
END
/******************************************************************************************/
/* Get Access Level  	  	  	  	  	  	  	  	 */
/******************************************************************************************/
Select @ALDesc = RTrim(LTrim(@ALDesc))
Select @Access_Level = AL_Id
From Access_Level
Where AL_Desc = @ALDesc
If @Access_Level Is Null 
 Begin
  Select 'Failed - incorrect access level'
  Return (-100)
 End
If @SecurityRoleMember is not Null
BEGIN
 	 IF @IsNTGroup = '1'
 	 BEGIN
 	  	 Select @SecurityRoleMemberId = User_Role_Security_Id
 	  	 FROM User_Role_Security
 	  	 WHERE GroupName = @SecurityRoleMember AND Role_User_Id = @UserId
 	  	 IF @SecurityRoleMemberId Is Null
 	  	 BEGIN
 	  	  	 EXECUTE spEM_CreateSecurityRoleMember @UserId,Null,@SecurityRoleMember,@InUserId,@DomainName,@SecurityRoleMemberId OUTPUT
 	  	 END
 	  	 SELECT @RoleUserId = Null
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select @RoleUserId = User_Id
 	  	 FROM Users
 	  	 WHERE UserName = @SecurityRoleMember and Role_Based_Security = 1
 	  	 IF @RoleUserId Is Null
 	  	 BEGIN
 	  	  	 Select 'Failed - could not find plant apps user'
 	  	  	 Return (-100)
 	  	 END
 	  	 EXECUTE spEM_CreateSecurityRoleMember @UserId,@RoleUserId, @SecurityRoleMember,@InUserId,@DomainName,@SecurityRoleMemberId OUTPUT
 	 END
END
 	 
Select @SecurityGroupId = Group_Id
From Security_Groups
Where Group_Desc = @SecurityGroupDesc
If @SecurityGroupId Is Null
Begin
  Execute spEM_CreateUserGroup @SecurityGroupDesc,@InUserId,@SecurityGroupId OUTPUT
  If @SecurityGroupId Is Null 
 	 Begin
 	   Select 'Failed - could not create user group'
 	   Return (-100)
 	 End
End
/******************************************************************************************/
/* Create/Update User Security 	   	   	  	  	  	 */
/******************************************************************************************/
If @SecurityGroupId Is Not Null And @UserId Is Not Null And @Access_Level Is Not Null
Begin
     /* Check for existing assignment */
     Select @Security_Id = Security_Id
     From User_Security
     Where Group_Id = @SecurityGroupId And User_Id = @UserId
     If @Security_Id Is Null
       Begin 
 	  	 Execute spEM_CreateUserSecurity  @SecurityGroupId, @UserId,@Access_Level,@InUserId, @Security_Id OUTPUT
 	  	 If @Security_Id Is Null 
 	  	   Begin
 	  	  	 Select 'Failed - could not create user Role membership'
 	  	  	 Return (-100)
 	  	   End
       End
     Else
       Begin
 	   IF @UserId <> 34 --do not allow change to administrator
           	 Execute spEM_ChangeUserAccess   @Security_Id,@Access_Level,@InUserId
       End
End
