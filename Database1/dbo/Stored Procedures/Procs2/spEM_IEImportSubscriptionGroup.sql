CREATE PROCEDURE dbo.spEM_IEImportSubscriptionGroup
@SubscriptionGroupDesc 	 nvarchar(255),
@StoredProcedureName 	 nvarchar(50),
@Priority 	  	  	  	 nvarchar(50),
@User_Id  	  	  	  	 Int
AS
Declare 	 @SubscriptionGroupId 	 Int,
 	  	 @iPriority 	  	  	 Int
Select @SubscriptionGroupDesc = LTrim(RTrim(@SubscriptionGroupDesc))
Select @StoredProcedureName = LTrim(RTrim(@StoredProcedureName))
Select @Priority  	  	 = LTrim(RTrim(@Priority))
If @SubscriptionGroupDesc = ''  	 Select @SubscriptionGroupDesc = null
If @StoredProcedureName = ''  	 Select @StoredProcedureName = null
If @Priority = ''  	  	  	 Select @Priority = null
/*Check From Desc*/
If @SubscriptionGroupDesc IS NULL
    Begin
      Select 'Failed -  subscription group missing'
      RETURN (-100)
    End
If isnumeric(@Priority) = 0  and @Priority is not null
  Begin
 	 Select 'Failed - Priority is not correct '
 	 Return(-100)
  End 
If @Priority is null
 	 select @iPriority = null
Else
 	 select @iPriority = Convert(Int,@Priority)
Select @SubscriptionGroupId = Subscription_Group_Id 
 	 From Subscription_Group
  Where Subscription_Group_Desc = @SubscriptionGroupDesc
If @SubscriptionGroupId IS Not NULL 
 	 Begin
 	  	 Select 'Failed -  subscription group already exists'
 	  	 RETURN (-100)
 	 End
If @SubscriptionGroupId is Null
  Begin
 	 Execute spEM_CreateSubscriptionGroup @SubscriptionGroupDesc,@User_Id,@SubscriptionGroupId Output
 	 If @SubscriptionGroupId IS  NULL 
 	  	 Begin
 	  	  	 Select 'Failed - unable to create Subscription Group'
 	  	  	 RETURN (-100)
 	  	 End
  End
Update Subscription_Group set Priority = @iPriority, Stored_Procedure_Name =@StoredProcedureName Where Subscription_Group_Id = @SubscriptionGroupId
RETURN(0)
