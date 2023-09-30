
CREATE PROCEDURE [dbo].[spMES_MessageQueueGet]
              @ServiceId   int
			  ,@InstanceId int
			  ,@QueueId    int
			  ,@MaxRows    int -- maximum number of messages to be returned
AS

select top (@MaxRows) Sequence, Message_Topic, Message_Text
  from BF_MessageQueue
  where Service_Id  = @ServiceId
    and Instance_Id = @InstanceId
    and Queue_Id    = @QueueId
  order by Sequence


