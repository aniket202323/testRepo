CREATE PROCEDURE dbo.spServer_CmnAddLogMessage 
@ServiceDesc nvarchar(50),
@TimeStamp datetime,
@Msg nvarchar(4000),
@MsgTimeStamp datetime
AS
Declare
  @ShouldInsert int
Select @ShouldInsert = 0
If ((@ShouldInsert = 0) And (CharIndex('err',@Msg) > 0)) Select @ShouldInsert = 1
If ((@ShouldInsert = 0) And (CharIndex('warn',@Msg) > 0)) Select @ShouldInsert = 1
If ((@ShouldInsert = 0) And (CharIndex('service',@Msg) > 0)) Select @ShouldInsert = 1
If (@ShouldInsert = 1)
  Insert Into Server_Log_Records(Service_Desc,Timestamp,Message,Message_TimeStamp) values(@ServiceDesc,@TimeStamp,@Msg,@MsgTimeStamp)
