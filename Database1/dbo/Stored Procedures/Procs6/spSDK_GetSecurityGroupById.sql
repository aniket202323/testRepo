CREATE PROCEDURE dbo.spSDK_GetSecurityGroupById
 	 @SecurityGroupId 	  	  	  	 INT
AS
SELECT 	 SecurityGroupId = Group_Id,
 	  	  	  	 GroupName = Group_Desc,
 	  	  	  	 CommentId = Comment_Id
 	 FROM 	 Security_Groups
 	 WHERE 	 Group_Id = @SecurityGroupId
