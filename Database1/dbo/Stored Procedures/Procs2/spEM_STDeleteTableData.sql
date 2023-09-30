CREATE PROCEDURE dbo.spEM_STDeleteTableData
 	 @TriggerId 	  	  	  	  	 Int,
 	 @UserId 	  	  	  	  	  	  	 Int
  AS
 	  	 
Delete From Subscription_Trigger Where Subscription_Trigger_Id = @TriggerId
