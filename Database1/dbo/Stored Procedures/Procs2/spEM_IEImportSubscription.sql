CREATE PROCEDURE dbo.spEM_IEImportSubscription
@SubscriptionGroupDesc 	 nvarchar(255),
@SubscriptionDesc 	  	 nvarchar(255),
@TimeInterval 	  	  	 nvarchar(50),
@TimeOffset 	  	  	 nvarchar(50),
@TableDesc 	  	  	 nvarchar(50),
@KeyDesc 	  	  	  	 nvarchar(50),
@KeyDesc2 	  	  	  	 nvarchar(50),
@User_Id  	  	  	  	 Int
AS
Declare 	 @SubscriptionId 	  	 Int,
 	  	 @SubscriptionGroupId 	 Int,
 	  	 @iTimeInterval 	  	  	 Int,
 	  	 @iTimeOffset 	  	  	 Int,
 	  	 @iTableId 	  	  	  	 Int,
 	  	 @iKeyId 	  	  	  	 Int,
 	  	 @iLineId 	  	  	  	 Int
Select @SubscriptionDesc = LTrim(RTrim(@SubscriptionDesc))
Select @SubscriptionGroupDesc = LTrim(RTrim(@SubscriptionGroupDesc))
Select @TimeInterval  	 = LTrim(RTrim(@TimeInterval))
Select @TimeOffset  	  	 = LTrim(RTrim(@TimeOffset))
Select @TableDesc  	  	 = LTrim(RTrim(@TableDesc))
Select @KeyDesc  	  	 = LTrim(RTrim(@KeyDesc))
Select @KeyDesc2  	  	 = LTrim(RTrim(@KeyDesc2))
If @SubscriptionGroupDesc = ''  	 Select @SubscriptionGroupDesc = null
If @SubscriptionDesc = ''  	 Select @SubscriptionDesc = null
If @TimeInterval = ''  	  	 Select @TimeInterval = null
If @TimeOffset = ''  	  	 Select @TimeOffset = null
If @TableDesc = ''  	  	 Select @TableDesc = null
If @KeyDesc = ''  	  	 Select @KeyDesc = null
If @KeyDesc2 = ''  	  	 Select @KeyDesc2 = null
/*Check From Desc*/
If @SubscriptionGroupDesc IS NULL
    Begin
      Select 'Failed -  subscription group missing'
      RETURN (-100)
    End
If @SubscriptionDesc IS NULL
    Begin
      Select 'Failed -  Subscription missing'
      RETURN (-100)
    End
If isnumeric(@TimeInterval) = 0  and @TimeInterval is not null
  Begin
 	 Select 'Failed - Time Interval is not correct '
 	 Return(-100)
  End 
If isnumeric(@TimeOffset) = 0  and @TimeOffset is not null
  Begin
 	 Select 'Failed - Time Offset is not correct '
 	 Return(-100)
  End 
If @TableDesc is Null
 	 Select @iTableId = Null
Else 	 If @TableDesc = 'Events'
 	 Select @iTableId = 1
Else 	 If @TableDesc = 'Production_Plan'
 	 Select @iTableId = 7
Else 	 
  Begin
 	 Select 'Failed - Table Name is not correct'
 	 Return(-100)
  End 
If @KeyDesc is Null 
 	 Select @iKeyId = Null
Else 	 If @TableDesc is Null
  Begin
 	 Select 'Failed - Table Name not found for key'
 	 Return(-100)
  End 
Else 	 If @TableDesc = 'Events'
 	 Begin
 	  	 Select @iLineId = PL_Id from prod_Lines where pL_Desc = @KeyDesc
 	  	 If @iLineId is null
 	  	   Begin
 	  	  	 Select 'Failed - Key [Prod Line] not found'
 	  	  	 Return(-100)
 	  	   End 
 	  	 Select @iKeyId = PU_Id from prod_Units where pu_Desc = @KeyDesc2 and PL_Id = @iLineId
 	  	 If @iKeyId is null
 	  	   Begin
 	  	  	 Select 'Failed - Key 2 [Prod Unit] not found'
 	  	  	 Return(-100)
 	  	   End 
 	 End
Else 	 If @TableDesc = 'Production_Plan'
 	 Begin
 	  	 Select @iKeyId = Path_Id From PrdExec_Paths where  Path_Code = @KeyDesc
 	  	 If @iKeyId is null
 	  	   Begin
 	  	  	 Select 'Failed - Key [Path Code] not found'
 	  	  	 Return(-100)
 	  	   End 
 	 End
If @TimeInterval is null
 	 select @iTimeInterval = null
Else
 	 select @iTimeInterval = Convert(Int,@TimeInterval)
If @TimeOffset is null
 	 select @iTimeOffset = null
Else
 	 select @iTimeOffset = Convert(Int,@TimeOffset)
Select @SubscriptionGroupId = Subscription_Group_Id 
 	 From Subscription_Group
  Where Subscription_Group_Desc = @SubscriptionGroupDesc
Select @SubscriptionId = Subscription_Id 
 	 From Subscription
  Where Subscription_Desc = @SubscriptionDesc
If @SubscriptionId IS Not NULL 
 	 Begin
 	  	 Select 'Failed -  Subscription description already exists'
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
Execute spEM_CreateSubscription @SubscriptionDesc,@SubscriptionGroupId,@User_Id,@SubscriptionId output
If @SubscriptionId IS NULL
 	 Begin
 	  	 Select 'Failed - Could not create subscription'
 	  	 RETURN (-100)
 	 End
Execute spEM_PutSubscription @SubscriptionId,@SubscriptionDesc,@iTimeInterval,@iTimeOffset,1,@iKeyId,@iTableId,@User_Id
RETURN(0)
