CREATE PROCEDURE dbo.spSDK_QueryTransactionGroups
 	 @UserId 	  	  	  	  	 INT,
 	 @GroupMask 	  	  	  	 nvarchar(50)
AS
SET 	 @GroupMask = REPLACE(COALESCE(@GroupMask, '*'), '*', '%')
SET 	 @GroupMask = REPLACE(REPLACE(@GroupMask, '?', '_'), '[', '[[]')
SELECT 	 TransactionGroupId = Transaction_Grp_Id,
 	  	  	 GroupName = Transaction_Grp_Desc
 	 FROM 	 Transaction_Groups
 	 WHERE 	 Transaction_Grp_Desc LIKE @GroupMask
