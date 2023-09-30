CREATE PROCEDURE dbo.spEM_OrderSubscriptionGroup
  @SubscriptionGroupId      int,
  @SubscriptionGroupPriority int,
  @User_Id int
  AS
  DECLARE   @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_OrderSubscriptionGroup',
                Convert(nVarChar(10),@SubscriptionGroupId) + ','  + 
 	  	 Convert(nVarChar(10), @SubscriptionGroupPriority) + ','  + 
 	  	 Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Order the Subscription Group
  --
  UPDATE Subscription_Group SET Priority = @SubscriptionGroupPriority WHERE Subscription_Group_Id = @SubscriptionGroupId
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
