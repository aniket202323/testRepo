CREATE PROCEDURE dbo.spEM_XrefCheckNewText
 	 @TableId Int,
 	 @DS_Id 	 Int,
 	 @ActualText 	 nvarchar(255),
 	 @subscriptionId 	  	 Int
  AS
 	 Declare @Id int
 	 Select @ActualText = ltrim(rtrim(@ActualText))
 	 If @subscriptionId is null
 	  	 Select @Id = DS_XRef_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Text = @ActualText and Subscription_Id is Null
 	 Else
 	  	 Select @Id = DS_XRef_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Text = @ActualText and Subscription_Id = @subscriptionId
 	 If @Id is null
 	  	 Return(0)
 	 Else
 	  	 Return(-100)
