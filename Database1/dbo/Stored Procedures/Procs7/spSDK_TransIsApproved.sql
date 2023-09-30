CREATE PROCEDURE dbo.spSDK_TransIsApproved
 	 @TransId 	  	  	  	  	 INT,
 	 @Approved 	  	  	  	 INT  	  	  	  	 OUTPUT 
AS
-- Return Status
-- 	  	 0 = Success
SELECT 	 @Approved = CASE WHEN Approved_On IS NULL THEN 0 ELSE 1 END
 	 FROM 	 Transactions
 	 WHERE 	 Trans_Id = @TransId
RETURN(0)
