CREATE PROCEDURE dbo.spEM_XrefGetData
 	 @TableId 	  	  	  	 Int,
 	 @ActualId 	  	  	  	 BigInt
  AS
   Select  DS_XRef_Id,DS_Id,Foreign_Key From Data_Source_XRef 
 	 Where Table_Id = @TableId and Actual_Id = @ActualId and Subscription_Id Is Null
