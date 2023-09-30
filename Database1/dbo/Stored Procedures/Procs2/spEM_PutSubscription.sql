CREATE PROCEDURE dbo.spEM_PutSubscription
  @SubscriptionId int,
  @Description  nvarchar(255),
  @Interval 	  	 Int,
  @Offset 	  	  	 Int,
  @IsActive 	  	 TinyInt,
  @KeyId 	  	  	 Int,
  @TableId 	  	 Int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create data type.
  --
 	 DECLARE @Insert_Id integer 
 	 Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	  	 VALUES (1,@User_Id,'spEM_PutSubscription',
 	  	             IsNull(Convert(nVarChar(10), @SubscriptionId),'Null') + ','  + 
 	  	             @Description + ','  + 
 	  	             IsNull(Convert(nVarChar(10), @Interval),'Null') + ','  + 
 	  	             IsNull(Convert(nVarChar(10), @Offset),'Null') + ','  + 
 	  	             IsNull(Convert(nVarChar(10), @IsActive),'Null') + ','  + 
 	  	  	  	   Convert(nVarChar(10), @User_Id),
 	  	            dbo.fnServer_CmnGetDate(getUTCdate()))
 	 select @Insert_Id = Scope_Identity()
  Update Subscription Set Subscription_Desc = @Description,Time_Trigger_Interval = @Interval,
 	  	  	  	  	 Time_Trigger_Offset = @Offset,Is_Active = @IsActive, Key_Id = @KeyId,
 	  	  	  	  	 Table_Id = @TableId
  	  	 Where Subscription_Id = @SubscriptionId 
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
  RETURN(0)
