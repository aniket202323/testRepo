CREATE PROCEDURE dbo.spCSS_InitMessageLog 
@Type int, 
@Client_Connection_Id int,
@MessageLogId int OUTPUT
AS
DECLARE @UTCNow Datetime,@DbNow Datetime
SELECT @UTCNow = Getutcdate()
SELECT @DbNow = dbo.fnServer_CmnGetdate(@UTCNow)
INSERT INTO Message_Log_Header (Timestamp, Type, Client_Connection_Id) VALUES(@DbNow, @Type, @Client_Connection_Id)
SELECT @MessageLogId = Scope_Identity()
