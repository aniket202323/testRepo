
CREATE PROCEDURE [dbo].[spMES_MessageQueueAdd]
              @ServiceId   int
			  ,@InstanceId int
			  ,@QueueId    int
              ,@MsgTopic   nvarchar(100) = null
              ,@MsgText    nvarchar(max) = Null
AS

Declare @Sequence bigint

Select @Sequence = max(Sequence)
  from BF_MessageQueue
  where Service_Id = @ServiceId
    and Instance_Id = @InstanceId
    and Queue_Id = @QueueId

if (@Sequence is null) set @Sequence = 0

Set @Sequence = @Sequence + 1

insert into BF_MessageQueue (Service_Id, Instance_Id, Queue_Id, Sequence, Message_Topic, Message_Text)
  values (@ServiceId, @InstanceId, @QueueId, @Sequence, @MsgTopic, @MsgText)

		
