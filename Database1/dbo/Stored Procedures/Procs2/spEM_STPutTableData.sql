CREATE PROCEDURE dbo.spEM_STPutTableData
 	 @SubscriptionId 	  	  	 Int,
 	 @TableId 	  	  	  	  	  	 Int,
 	 @KeyId 	  	  	  	  	  	  	 Int,
 	 @ColumnName 	  	  	  	  	 nVarChar(100),
 	 @FromId 	  	  	  	  	  	  	 Int,
 	 @ToId 	  	  	  	  	  	  	  	 Int,
 	 @UserId 	  	  	  	  	  	  	 Int,
 	 @TriggerId 	  	  	  	  	 Int Output
  AS
 	  	 
 	 If @TriggerId is null
 	  	 Begin
 	  	  	  	 Insert Into Subscription_Trigger(Subscription_Id,Table_Id,Key_Id,Column_Name,From_Value,To_Value)
 	  	  	  	  	 Values (@SubscriptionId,@TableId,@KeyId,@ColumnName,@FromId,@ToId)
 	  	  	  	 Select  @TriggerId  = SCOPE_IDENTITY()
 	  	 End
 	 Else
 	  	 Update Subscription_Trigger Set Table_Id = @TableId,Key_Id = @KeyId,Column_Name = @ColumnName,From_Value = @FromId,To_Value = @ToId
 	  	  	 Where Subscription_Trigger_Id = @TriggerId
