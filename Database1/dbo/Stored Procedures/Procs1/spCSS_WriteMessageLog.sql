CREATE PROCEDURE DBO.spCSS_WriteMessageLog 
@MessageLogId int, 
@Msg varchar(8000)
AS
INSERT INTO Message_Log_Detail (Message_Log_Id, Message) VALUES(@MessageLogId, @Msg)
