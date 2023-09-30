CREATE PROCEDURE dbo.spEM_RenameSubscriptionGroup
  @SubscriptionGroupId   int,
  @Subscription_Desc nvarchar(255),
  @User_Id    int
  AS
  DECLARE @Insert_Id integer,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameSubscriptionGroup',
                Convert(nVarChar(10),@SubscriptionGroupId) + ','  + 
                @Subscription_Desc + ','  + 
                Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
 	 Update Subscription_Group Set Subscription_Group_Desc = @Subscription_Desc  Where Subscription_Group_Id = @SubscriptionGroupId
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
