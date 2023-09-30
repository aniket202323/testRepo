CREATE PROCEDURE dbo.spEM_IEImportUserGroups
@Group_Desc 	 nVarChar(100),
@UserName 	 nVarChar(100),
@AL_Desc 	 nVarChar(100),
@In_User_Id 	 int
AS
Declare @Description  	 nVarChar(100),
 	  	 @Group_Id  	  	 int,
 	  	 @User_Id 	  	 int,
 	  	 @Access_Level 	 int,
 	  	 @Security_Id 	 Int
/* Initialization */
Select  	 @Group_Id  	   = Null,
 	  	 @Access_Level = Null,
 	  	 @Security_Id  = Null,
 	  	 @User_Id 	   = Null
/******************************************************************************************/
/* Create/Update User Groups 	  	  	  	  	  	 */
/******************************************************************************************/
Select @Group_Desc = RTrim(LTrim(@Group_Desc))
Select @Group_Id = Group_Id
From Security_Groups
Where Group_Desc = @Group_Desc
If @Group_Id Is Null
Begin
  Execute spEM_CreateUserGroup @Group_Desc,@In_User_Id,@Group_Id OUTPUT
  If @Group_Id Is Null 
 	 Begin
 	   Select 'Failed - could not create user group'
 	   Return (-100)
 	 End
End
/******************************************************************************************/
/* Get User  	  	  	  	  	  	  	  	 */
/******************************************************************************************/
Select @UserName = RTrim(LTrim(@UserName))
Select @User_Id = User_Id
From Users
Where Username = @UserName
If @User_Id Is Null 
 Begin
  Select 'Failed - could not find user'
  Return (-100)
 End
/******************************************************************************************/
/* Get Access Level  	  	  	  	  	  	  	  	 */
/******************************************************************************************/
Select @AL_Desc = RTrim(LTrim(@AL_Desc))
Select @Access_Level = AL_Id
From Access_Level
Where AL_Desc = @AL_Desc
If @Access_Level Is Null 
 Begin
  Select 'Failed - incorrect access level'
  Return (-100)
 End
/******************************************************************************************/
/* Create/Update User Security 	   	   	  	  	  	 */
/******************************************************************************************/
If @Group_Id Is Not Null And @User_Id Is Not Null And @Access_Level Is Not Null
Begin
     /* Check for existing assignment */
     Select @Security_Id = Security_Id
     From User_Security
     Where Group_Id = @Group_Id And User_Id = @User_Id
     If @Security_Id Is Null
       Begin 
 	  	 Execute spEM_CreateUserSecurity  @Group_Id, @User_Id,@Access_Level,@In_User_Id, @Security_Id OUTPUT
 	  	 If @Security_Id Is Null 
 	  	   Begin
 	  	  	 Select 'Failed - could not create user membership'
 	  	  	 Return (-100)
 	  	   End
       End
     Else
       Begin
          Execute spEM_ChangeUserAccess   @Security_Id,@Access_Level,@In_User_Id
       End
End
