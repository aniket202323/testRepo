CREATE PROCEDURE dbo.spSDK_GetTransInfo
 	 @TransId 	  	  	  	  	 INT,
 	 @TransName 	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @TransGroup 	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @ApprovedUser 	  	  	 nvarchar(50) 	 OUTPUT,
 	 @EffectiveDate 	  	  	 DATETIME 	  	  	 OUTPUT,
 	 @TransCreateDate 	  	 DATETIME 	  	  	 OUTPUT,
 	 @ApprovedOn 	  	  	  	 DATETIME 	  	  	 OUTPUT,
 	 @CommentId 	  	  	  	 INT 	  	  	  	 OUTPUT
AS
-- Return Status
-- 	  	 0 = Success
SELECT 	 @EffectiveDate = t.Effective_Date,
 	  	  	 @ApprovedOn = t.Approved_On,
 	  	  	 @TransCreateDate = t.Trans_Create_Date,
 	  	  	 @ApprovedUser = u.UserName,
 	  	  	 @CommentId = t.Comment_Id,
 	  	  	 @TransName = Trans_Desc,
 	  	  	 @TransGroup = COALESCE(Transaction_Grp_Desc, '')
 	 FROM 	 Transactions t 	  	  	  	 LEFT JOIN
 	  	  	 Transaction_Groups tg 	 ON t.Transaction_Grp_Id = tg.Transaction_Grp_Id LEFT JOIN
 	  	  	 Users u 	  	  	  	  	  	 ON t.Approved_By = u.User_Id
 	 WHERE 	 Trans_Id = @TransId
RETURN(0)
