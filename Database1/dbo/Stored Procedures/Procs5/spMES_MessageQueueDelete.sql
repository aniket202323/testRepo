
CREATE PROCEDURE [dbo].[spMES_MessageQueueDelete]
              @ServiceId    int
			  ,@InstanceId  int
			  ,@QueueId     int
			  ,@Sequence    bigint = null -- Delete just one specific message
			  ,@EndSequence bigint = null -- Delete all messages up to and including this one
AS

if @Sequence is not null
begin
  delete from BF_MessageQueue
    where Service_Id  = @ServiceId
      and Instance_Id = @InstanceId
      and Queue_Id    = @QueueId
      and Sequence    = @Sequence
end

if @EndSequence is not null
begin
  delete from BF_MessageQueue
    where Service_Id   = @ServiceId
      and Instance_Id  = @InstanceId
      and Queue_Id     = @QueueId
      and Sequence    <= @EndSequence
end

