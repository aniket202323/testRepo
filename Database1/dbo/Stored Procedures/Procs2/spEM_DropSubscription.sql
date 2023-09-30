﻿CREATE PROCEDURE dbo.spEM_DropSubscription
  @Subscription_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Begin a transaction.
  --
  DECLARE  @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropSubscription',
                 convert(nVarChar(10),@Subscription_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
 	 Delete from Subscription_Trigger where subscription_Id = @Subscription_Id
 	 Delete From  Data_Source_XRef where subscription_Id = @Subscription_Id
   	 Delete from Subscription Where Subscription_Id = @Subscription_Id
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
