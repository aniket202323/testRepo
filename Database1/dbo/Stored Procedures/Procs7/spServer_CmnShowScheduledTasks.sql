Create Procedure dbo.spServer_CmnShowScheduledTasks
AS
Select ActualId = a.ActualId, 
       Owner = SubString(b.Owner,1,20), 
       WorkStarted = a.WorkStarted, 
       WorkStartedTime = Convert(nVarChar(20),a.WorkStartedTime),
       TaskDesc = b.TaskDesc
  From PendingTasks a
  Join Tasks b on b.TaskId = a.TaskId
  Order by b.Owner,b.TaskDesc,a.WorkStarted,a.ActualId
