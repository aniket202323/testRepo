
CREATE PROCEDURE [dbo].[spMES_MessageQueueCount]
              @ServiceId   int
              ,@InstanceId int
			  ,@QueueId    int
AS

select count(*) as 'Count'
  from BF_MessageQueue
  where Service_Id = @ServiceId
    and Instance_Id = @InstanceId
    and Queue_Id = @QueueId


