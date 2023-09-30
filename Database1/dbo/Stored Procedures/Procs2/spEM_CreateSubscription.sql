CREATE PROCEDURE dbo.spEM_CreateSubscription
  @Description  nvarchar(255),
  @Subscription_Group_Id Int,
  @User_Id int,
  @Subscription_Id int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create data type.
  --
DECLARE @Insert_Id integer 
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateSubscription',
                 @Description + ','  + 
 	  	  	   Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  INSERT INTO Subscription(Subscription_Desc,Last_Processed_Date,Subscription_Group_Id) 
 	  	  	 Select @Description,dbo.fnServer_CmnGetDate(getUTCdate()),@Subscription_Group_Id
  SELECT @Subscription_Id = Subscription_Id From Subscription where Subscription_Desc = @Description
  IF @Subscription_Id IS NULL
 	 BEGIN
 	    Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	    RETURN(1)
 	 END
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Subscription_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
