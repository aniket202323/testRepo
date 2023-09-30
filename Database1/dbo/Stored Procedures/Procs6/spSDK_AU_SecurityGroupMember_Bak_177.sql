CREATE procedure [dbo].[spSDK_AU_SecurityGroupMember_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@AccessLevel tinyint ,
@SecurityGroup nvarchar(50) ,
@SecurityGroupId int ,
@UserId int ,
@UserName nvarchar(30) 
AS
DECLARE @sAccessLevel VarChar(50)
DECLARE @OldUserId 	  	 Int
DECLARE @OldSecurityGroupId Int
DECLARE @ReturnMessages TABLE(msg VarChar(100))
SELECT @sAccessLevel = AL_Desc
FROM Access_Level
WHERE AL_Id = @AccessLevel
IF @Id is Not Null
BEGIN
 	 IF Not Exists(SELECT 1 FROM User_Security WHERE Security_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Security Group Member not found for update'
 	  	 RETURN(-100)
 	 END
 	 IF @UserId <> (SELECT User_Id FROM User_Security WHERE Security_Id = @Id)
 	 BEGIN
 	  	 SELECT 'User is not updatable'
 	  	 RETURN(-100)
 	 END
 	 IF @SecurityGroupId <> (SELECT Group_Id FROM User_Security WHERE Security_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Security group is not updatable'
 	  	 RETURN(-100)
 	 END
END
ELSE
BEGIN
 Select @Id = Security_Id
 	  From User_Security
 	  Where Group_Id = @SecurityGroupId And User_Id = @UserId
 	 IF @Id Is Not Null
 	 BEGIN
 	  	  	 SELECT 'Security Group Member already exists - add failed'
 	  	  	 RETURN(-100)
 	 END
END
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportUserGroups @SecurityGroup,@UserName,@sAccessLevel,@AppUserId
 	 
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
 Select @Id = Security_Id
 	  From User_Security
 	  Where Group_Id = @SecurityGroupId And User_Id = @UserId
RETURN(1)
