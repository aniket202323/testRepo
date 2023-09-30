CREATE PROCEDURE dbo.spEM_PutSubscriptionGroup
  @SubscriptionGroupId int,
  @Description nvarchar(255),
  @Priority 	 Int,
  @SpName 	  	 nvarchar(255),
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
 	  	 VALUES (1,@User_Id,'spEM_PutSubscriptionGroup',
 	  	             IsNull(Convert(nVarChar(10), @SubscriptionGroupId),'Null') + ','  + 
 	  	             @Description + ','  + 
 	  	             IsNull(Convert(nVarChar(10), @Priority),'Null') + ','  + 
 	  	             IsNull(@SpName,'Null') + ','  + 
 	  	  	  	   Convert(nVarChar(10), @User_Id),
 	  	            dbo.fnServer_CmnGetDate(getUTCdate()))
 	 select @Insert_Id = Scope_Identity()
  Update Subscription_Group Set Subscription_Group_Desc = @Description,Stored_Procedure_Name = @SpName,Priority = @Priority
  	  	 Where Subscription_Group_Id = @SubscriptionGroupId 
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
  RETURN(0)
