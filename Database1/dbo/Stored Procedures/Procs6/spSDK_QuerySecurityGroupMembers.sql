CREATE PROCEDURE dbo.spSDK_QuerySecurityGroupMembers
 	 @UserId 	  	  	  	  	 INT,
 	 @GroupMask 	  	  	 nvarchar(50),
 	 @UserMask 	  	  	  	 nvarchar(50),
 	 @AccessLevel 	  	 tinyint
AS
SET 	 @GroupMask = REPLACE(COALESCE(@GroupMask, '*'), '*', '%')
SET 	 @GroupMask = REPLACE(REPLACE(@GroupMask, '?', '_'), '[', '[[]')
SET 	 @UserMask = REPLACE(COALESCE(@UserMask, '*'), '*', '%')
SET 	 @UserMask = REPLACE(REPLACE(@UserMask, '?', '_'), '[', '[[]')
SELECT 	 SecurityGroupMemberId = us.Security_Id,
 	  	  	  	 GroupName = sg.Group_Desc,
 	  	  	  	 UserName = u.Username,
 	  	  	  	 AccessLevel = al.AL_Desc
 	 FROM 	 User_Security us
 	 JOIN 	 Security_Groups sg on sg.Group_Id = us.Group_Id
 	 JOIN 	 Users u on u.User_Id = us.User_Id
 	 JOIN 	 Access_Level al on al.AL_Id = us.Access_Level
 	 WHERE 	 sg.Group_Desc LIKE @GroupMask
 	 AND 	  	 u.Username LIKE @UserMask
 	 AND 	  	 (al.AL_Id = Case When @AccessLevel > 0 Then @AccessLevel Else 1 End
 	 OR 	  	  al.AL_Id = Case When @AccessLevel > 0 Then @AccessLevel Else 2 End
 	 OR 	  	  al.AL_Id = Case When @AccessLevel > 0 Then @AccessLevel Else 3 End
 	 OR 	  	  al.AL_Id = Case When @AccessLevel > 0 Then @AccessLevel Else 4 End)
 	 AND 	  	 U.Is_Role = 0
