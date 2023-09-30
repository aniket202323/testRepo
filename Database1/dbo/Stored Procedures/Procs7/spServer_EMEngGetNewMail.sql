CREATE PROCEDURE dbo.spServer_EMEngGetNewMail
 AS
Declare @NumRetries int
Declare @NumMinutes int
Declare @TimeLimit DateTime
Declare @EMailMessages Table (EM_Id int, EG_Id int, EM_Subject nvarchar(2000) null, EM_Content text null, Submitted_On datetime null, EM_Attachments nVarChar(1000) null, EM_Processed tinyint null, TableId int, KeyId int)
-- Messages will be marked processed after reaching BOTH limits
Set @NumRetries = 3
Set @NumMinutes = 15
Set @TimeLimit = DateAdd(minute, -1 * @NumMinutes, dbo.fnServer_CmnGetDate(GetUtcDate()))
insert into @EMailMessages (EM_Id, EG_Id, EM_Subject, EM_Content, Submitted_On, EM_Attachments, EM_Processed, TableId, KeyId)
Select EM_Id, EG_Id, EM_Subject, EM_Content, Submitted_On, EM_Attachments, EM_Processed, Table_Id, Key_Id
  from Email_Messages
  where EM_Processed = 0 or EM_Processed > 10
-- Increment the EM_Processed value to keep track of retries (Start at 11)
-- Don't let it go over 200
Update Email_Messages set EM_Processed = 11 where EM_Id in (Select EM_Id from @EMailMessages where EM_Processed = 0)
Update Email_Messages set EM_Processed = EM_Processed + 1 where EM_Id in (Select EM_Id from @EMailMessages where EM_Processed between 11 and 199)
-- Check to see if this is the last try, if so mark it failed so it won't be loaded next time.
Update Email_Messages set EM_Processed = 2 where EM_Id in 
 (Select EM_Id
    from @EMailMessages
    where ((EM_Processed - 10) >= @NumRetries) and ((Submitted_On is Null) or (Submitted_On < @TimeLimit)))
-- Check to see if this is the last try, if so remove it from the results.
Delete @EmailMessages where EM_Id in 
 (Select EM_Id
    from @EMailMessages
    where ((EM_Processed - 10) >= @NumRetries) and ((Submitted_On is Null) or (Submitted_On < @TimeLimit)))
-- Return the messages
Select EM_Id, EG_Id, EM_Subject, EM_Content, Submitted_On, EM_Attachments, TableId, KeyId
  from @EMailMessages
