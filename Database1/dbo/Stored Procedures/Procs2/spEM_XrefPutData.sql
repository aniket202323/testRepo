CREATE PROCEDURE dbo.spEM_XrefPutData
 	 @DSId 	  	  	  	  	  	 Int,
 	 @TableId 	  	  	  	 Int,
 	 @ActualId 	  	  	  	 BigInt,
 	 @ForeignKey 	  	  	 nvarchar(255),
 	 @ActualText 	  	  	 nvarchar(255),
 	 @subscriptionId 	 Int,
 	 @XMLHeader 	  	  	 nvarchar(255), 	 
 	 @UserId 	  	  	  	  	 Int,
 	 @XRefId  	  	  	  	 Int  Output
  AS
 	 If @ForeignKey = '' Select @ForeignKey = Null
 	 DECLARE @Insert_Id Int 
 	 Insert into Audit_Trail(Application_id,User_id,Sp_Name,Parameters,StartTime)
 	  	 VALUES (1,1,'spEM_XrefPutData',
 	  	  	  	  	  	  	  	 IsNull(convert(nVarChar(10),@DSId),'Null') + ','  + 
 	  	  	  	  	  	  	  	 IsNull(convert(nVarChar(10),@TableId),'Null') + ','  + 
 	  	  	  	  	  	  	  	 IsNull(convert(nVarChar(10),@ActualId),'Null') + ','  + 
 	  	  	  	  	  	  	  	 IsNull(@ForeignKey,'Null') + ','  + 
 	  	  	  	  	  	  	  	 IsNull(@ActualText,'Null') + ','  + 
 	  	  	  	  	  	  	  	 IsNull(@XMLHeader,'Null') + ','  + 
 	  	  	  	  	  	  	  	 Isnull(Convert(nVarChar(10), @UserId),'Null')  + ','  +
 	  	  	  	  	  	  	  	 IsNull(convert(nVarChar(10),@XRefId),'Null'),dbo.fnServer_CmnGetDate(getUTCdate()))
 	 select @Insert_Id = scope_identity()
If @XMLHeader = '' select @XMLHeader = Null
If @XRefId is Null
 	 Begin
 	  	 If @ActualId < 0  -- putting actual_text
 	  	  	 Begin
 	  	  	  	 If @subscriptionId Is Null
 	  	  	  	  	 IF @ForeignKey Is Null
 	  	  	  	  	  	 Select @XRefId = DS_XRef_Id From Data_Source_XRef Where DS_Id = @DSId and Table_Id = @TableId and Actual_Text = @ActualText and Subscription_Id Is Null and Foreign_Key IS NULL
 	  	  	  	  	 ELSE
 	  	  	  	  	  	 Select @XRefId = DS_XRef_Id From Data_Source_XRef Where DS_Id = @DSId and Table_Id = @TableId and Actual_Text = @ActualText and Subscription_Id Is Null and Foreign_Key = @ForeignKey
 	  	  	  	 Else
 	  	  	  	  	 IF @ForeignKey Is Null
 	  	  	  	  	  	 Select @XRefId = DS_XRef_Id From Data_Source_XRef Where DS_Id = @DSId and Table_Id = @TableId and Actual_Text = @ActualText and Subscription_Id = @subscriptionId and Foreign_Key IS NULL
 	  	  	  	  	 ELSE
 	  	  	  	  	  	 Select @XRefId = DS_XRef_Id From Data_Source_XRef Where DS_Id = @DSId and Table_Id = @TableId and Actual_Text = @ActualText and Subscription_Id = @subscriptionId and Foreign_Key = @ForeignKey
 	  	  	  	 Select @ActualId = Null
 	  	  	 End
 	  	 Else
 	  	  	 Begin
 	  	  	  	 If @subscriptionId Is Null
 	  	  	  	  	 IF @ForeignKey Is Null
 	  	  	  	  	  	 Select @XRefId = DS_XRef_Id From Data_Source_XRef Where DS_Id = @DSId and Table_Id = @TableId and Actual_Id = @ActualId and Subscription_Id Is Null and Foreign_Key IS NULL
 	  	  	  	  	 ELSE
 	  	  	  	  	  	 Select @XRefId = DS_XRef_Id From Data_Source_XRef Where DS_Id = @DSId and Table_Id = @TableId and Actual_Id = @ActualId and Subscription_Id Is Null and Foreign_Key = @ForeignKey
 	  	  	  	 Else
 	  	  	  	  	 IF @ForeignKey Is Null
 	  	  	  	  	  	 Select @XRefId = DS_XRef_Id From Data_Source_XRef Where DS_Id = @DSId and Table_Id = @TableId and Actual_Id = @ActualId and Subscription_Id = @subscriptionId and Foreign_Key IS NULL
 	  	  	  	  	 ELSE
 	  	  	  	  	  	 Select @XRefId = DS_XRef_Id From Data_Source_XRef Where DS_Id = @DSId and Table_Id = @TableId and Actual_Id = @ActualId and Subscription_Id = @subscriptionId and Foreign_Key = @ForeignKey
 	  	  	  	 Select @ActualText = Null
 	  	  	 End
 	  	 If @XRefId is Null
 	  	  	 Begin
 	  	  	  	 Insert Into Data_Source_XRef (DS_Id,Table_Id,Actual_Id,Actual_Text,Foreign_Key,Subscription_Id,XML_Header) Values (@DSId,@TableId,@ActualId,@ActualText,@ForeignKey,@subscriptionId,@XMLHeader)
 	  	  	  	 Select @XRefId = SCOPE_IDENTITY()
  	  	  	  	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
 	  	  	  	 Return(0)
 	  	  	 End
 	 End
/* Update is only to FK and XML_Header*/
  If @DSId is Null
  BEGIN
 	 Update Data_Source_XRef Set Foreign_Key = @ForeignKey,XML_Header =@XMLHeader  Where DS_XRef_Id = @XRefId
  END
  Else 
  BEGIN
   	 Update Data_Source_XRef Set Foreign_Key = @ForeignKey,XML_Header =@XMLHeader, DS_Id= @DSId  Where DS_XRef_Id = @XRefId
  END
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
 	 Return(0)
