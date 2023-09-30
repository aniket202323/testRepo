CREATE PROCEDURE dbo.spEM_IEImportEMailMessages
 	 @EMailMessageId 	 nVarChar(100),
 	 @Subject 	  	  	 nvarchar(2000),
 	 @Text 	  	  	 nvarchar(2000),
 	 @EG_Desc 	  	  	 nVarChar(100),
 	 @SeverityDesc 	  	 nVarChar(100),
 	 @User_Id 	  	  	 Int,
 	 @TransType 	  	 nVarChar(1)
AS
Declare 	 @EG_Id int,
 	  	 @iEmailId 	 Int,
 	  	 @iEmailCheck 	 Int,
 	  	 @Severity 	  	 TinyInt
Select @EG_Id = Null
------------------------------------------------------------------------------------------
-- Trim Parameters
------------------------------------------------------------------------------------------
Select @EMailMessageId = LTrim(RTrim(@EMailMessageId))
Select @EG_Desc = LTrim(RTrim(@EG_Desc))
Select @SeverityDesc = LTrim(RTrim(@SeverityDesc))
Select @Subject = LTrim(RTrim(@Subject))
Select @Text = LTrim(RTrim(@Text))
SELECT @TransType = LTrim(RTrim(@TransType))
If @EMailMessageId = '' 	 Select @EMailMessageId = Null
If @EG_Desc = '' 	 Select @EG_Desc = Null
If @SeverityDesc = '' 	 Select @SeverityDesc = Null
If @Subject = '' 	 Select @Subject = Null
If @Text = '' 	 Select @Text = Null
-- Verify Arguments 
IF @TransType NOT IN ('I','U','D')
BEGIN
   Select 'Failed - Select type not correct'
   Return(-100)
END
If @EMailMessageId IS NULL
 BEGIN
   Select 'Failed - E-Mail Message Id is Missing'
   Return(-100)
 END
If IsNumeric (@EMailMessageId) = 0 
 BEGIN
   Select 'Failed - E-Mail Message Id is not Correct'
   Return(-100)
 END
Select @iEmailId = Convert(Int,@EMailMessageId)
If @Subject IS NULL
 BEGIN
   Select 'Failed - Subject is Missing'
   Return(-100)
 END
If @iEmailId < 0 and (@TransType = 'I' Or @TransType = 'D')
BEGIN
 	 Select 'Failed - E-Mail Message Id < 0 is Reserved (no inserts/deletes)'
 	 Return(-100)
END
If @EG_Desc IS Not NULL
 BEGIN
 	 Select @EG_Id = EG_Id 
 	   from Email_Groups 
 	   where EG_Desc = @EG_Desc
 	 
 	 If @EG_Id is NULL
 	   exec spEM_CreateEMailGroup @EG_Desc, @User_Id, @EG_Id OUTPUT
 END
If @SeverityDesc IS Not NULL
BEGIN
 	 Select @Severity = case WHEN @SeverityDesc = 'Critical' THEN 1
 	  	 WHEN @SeverityDesc = 'Warning' THEN 2 
 	  	 WHEN @SeverityDesc = 'Informational' THEN 3
 	  	 ELSE 0
 	  	 END 
END
If  @TransType = 'U' Or @TransType = 'D'
BEGIN
 	 Select @iEmailCheck = Null
 	 Select @iEmailCheck = Message_id from EMail_Message_Data Where Message_id = @iEmailId
 	 If @iEmailCheck Is Null
 	 BEGIN
 	  	 Select 'Failed - E-Mail Message Id not Found to update/Delete'
 	  	 Return(-100)
 	 END
END
If @TransType = 'D'
BEGIN
 	 EXECUTE spEM_DeleteEmailMessageData @iEmailId,@User_Id
END
If @TransType = 'U'
BEGIN
 	 EXECUTE spEM_PutEmailMessageData @iEmailId,@Subject,@EG_Id,@iEmailId,@Text,@Severity,@User_Id
END
If @TransType = 'I'
BEGIN
 	 EXECUTE spEM_PutEmailMessageData Null,@Subject,@EG_Id,@iEmailId,@Text,@Severity,@User_Id
END
