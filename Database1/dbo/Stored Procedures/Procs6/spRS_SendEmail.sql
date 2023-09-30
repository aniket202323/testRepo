CREATE PROCEDURE [dbo].[spRS_SendEmail] 
@Subject varchar(100), 
@Body varchar(8000)
AS
insert into email_messages(eg_id, em_subject, em_content)
Values(1, @Subject, @Body)
