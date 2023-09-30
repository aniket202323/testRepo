CREATE PROCEDURE dbo.spSDK_QuerySecurityGroups
 	 @UserId 	  	  	  	  	 INT,
 	 @GroupMask 	  	  	  	 nvarchar(50)
AS
SET 	 @GroupMask = REPLACE(COALESCE(@GroupMask, '*'), '*', '%')
SET 	 @GroupMask = REPLACE(REPLACE(@GroupMask, '?', '_'), '[', '[[]')
SELECT 	 SecurityGroupId = Group_Id,
 	  	  	  	 GroupName = Group_Desc,
 	  	  	  	 CommentId = Comment_Id
 	 FROM 	 Security_Groups
 	 WHERE 	 Group_Desc LIKE @GroupMask
