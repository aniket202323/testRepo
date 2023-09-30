CREATE PROCEDURE dbo.spEM_PutEmailMessageData
 	 @MessageId 	 Int,
 	 @SubjectText 	 nvarchar(2000),
 	 @EGId 	  	 Int,
 	 @NewId 	  	 int,
 	 @MessageText 	 nvarchar(2000),
 	 @Severity 	  	 TinyInt,
 	 @UserId 	  	 Int
AS
 DECLARE @InsertId integer 
 Insert into Audit_Trail(Application_id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,1,'spEM_PutEmailMessageData',  Isnull(convert(nVarChar(10),@MessageId),'Null') + ','  +
 	  	  	 Isnull(substring(@SubjectText,1,100),'Null') + ',' +
 	  	  	 Isnull(convert(nVarChar(10),@EGId),'Null') + ',' +
 	  	  	 Isnull(convert(nVarChar(10),@NewId),'Null') + ',' +
 	  	  	 Convert(nVarChar(10), @Userid),dbo.fnServer_CmnGetDate(getUTCdate()))
 select @InsertId = scope_Identity()
If @MessageId is Not null
 	 Update Email_Message_Data Set Message_Subject = @SubjectText,EG_Id = @EGId,Message_id = @NewId, Message_Text=@MessageText,Severity = @Severity Where Message_id = @MessageId
Else
  BEGIN
 	 If (select Count(*) From Email_Message_Data Where Message_id = @NewId) > 0
 	  	 Return(-100)
 	 Insert INto Email_Message_Data (Message_id,Message_Subject,Message_Text,EG_Id,Severity)
 	  	 Select @NewId,@SubjectText,@MessageText,@EGId,@Severity
  END
Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @InsertId
