-----------------------------------------------------------
-- Type: Stored Procedure
-- Name: spServer_CmnGetModifyIds
-----------------------------------------------------------
CREATE PROCEDURE [dbo].[spServer_CmnGetModifyIds]
@TaskId int,
@Owner nVarChar(100)
AS 
declare @x int
-- 	 BSeely 	 2007/04/20 	 PendingTasks were executing in the wrong order.  In addition, they weren't picked up if they
-- 	 were orphaned by a Server Shutdown.  A limit has been placed on the number of records that are returned because
-- 	 many of the Services are single threaded (EventMgr is multi-threaded but seems to process Pending Tasks with the
-- 	 same thread as used for Historian triggered models).
--  The above added the "problem" that if you legitimately have more Tasks show up than the top 100 can take
--  you will fall behind.  So, we put in a test to see how many tasks are present and try to increase the number if
--  we seem to be falling behind.  I think we'd prefer to do this logic in the service, but for now this is the best
--  we can do.
-- Tom Nettell 5/2/2011
-- added the new column ET_Id to the select statements
-- Tom Nettell 7/5/2011
-- added the new column PU_Id to the select statements
-- Marty 4/17/2012
-- added the new column OldTimestamp to the select statements
If (@TaskId Is NULL) Or (@TaskId = 0)
  Begin
 	  	 select @x = count(Pending_Task_Id) from PendingTasks WITH (NOLOCK index(PendingTasks_IX_TaskIdPendingTaskId)) 
 	  	  	 where TaskId in (select TaskId from Tasks with (NOLOCK) where Owner = @Owner)
 	  	 if (@x < 500) 
 	     Select Top 100 a.ActualId,a.TaskId,a.Pending_Task_Id,b.ET_Id,a.PU_Id,a.OldTimestamp,a.Misc
 	       From PendingTasks a WITH (NOLOCK index(PendingTasks_IX_TaskIdPendingTaskId)) , Tasks b
 	  	  	  	 where (a.TaskId = b.TaskId) and (a.TaskId in (select TaskId from Tasks with (NOLOCK) where Owner = @Owner)
 	  	  	  	  	 and (a.WorkStarted = 0
 	         Or (a.WorkStarted = 1 And Datediff(Hour, WorkStartedTime, dbo.fnServer_CmnGetDate(GetUTCDate())) > 1)))
 	  	  	  	 order by Pending_Task_Id
 	  	 else if (@x < 5000)
 	     Select Top 1500 a.ActualId,a.TaskId,a.Pending_Task_Id,b.ET_Id,a.PU_Id,a.OldTimestamp,a.Misc
 	       From PendingTasks a WITH (NOLOCK index(PendingTasks_IX_TaskIdPendingTaskId)) , Tasks b
 	  	  	  	 where (a.TaskId = b.TaskId) and (a.TaskId in (select TaskId from Tasks with (NOLOCK) where Owner = @Owner)
 	  	  	  	  	 and (a.WorkStarted = 0
 	         Or (a.WorkStarted = 1 And Datediff(Hour, WorkStartedTime, dbo.fnServer_CmnGetDate(GetUTCDate())) > 1)))
 	  	  	  	 order by Pending_Task_Id
 	  	 else
 	     Select Top 10000 a.ActualId,a.TaskId,a.Pending_Task_Id,b.ET_Id,a.PU_Id,a.OldTimestamp,a.Misc
 	       From PendingTasks a WITH (NOLOCK index(PendingTasks_IX_TaskIdPendingTaskId)) , Tasks b
 	  	  	  	 where (a.TaskId = b.TaskId) and (a.TaskId in (select TaskId from Tasks with (NOLOCK) where Owner = @Owner)
 	  	  	  	  	 and (a.WorkStarted = 0
 	         Or (a.WorkStarted = 1 And Datediff(Hour, WorkStartedTime, dbo.fnServer_CmnGetDate(GetUTCDate())) > 1)))
 	  	  	  	 order by Pending_Task_Id
  End
Else
  Begin
 	  	 select @x = count(Pending_Task_Id) from PendingTasks WITH (NOLOCK)  	 where TaskId = @TaskId
 	  	 if (@x < 500) 
 	     Select Top 100 ActualId,Pending_Task_Id,b.ET_Id,a.PU_Id,a.OldTimestamp,a.Misc
 	       From PendingTasks a WITH (NOLOCK)
 	  	  	  	 Join Tasks b on (b.TaskId = a.TaskId) 	       
 	       Where a.TaskId = @TaskId
 	         And (WorkStarted = 0 Or (WorkStarted = 1 And Datediff(Hour, WorkStartedTime, dbo.fnServer_CmnGetDate(GetUTCDate())) > 1))
 	       Order By Pending_Task_Id
 	  	 else if (@x < 5000)
 	     Select Top 1500 ActualId,Pending_Task_Id,b.ET_Id,a.PU_Id,a.OldTimestamp,a.Misc
 	       From PendingTasks a WITH (NOLOCK)
 	  	  	  	 Join Tasks b on (b.TaskId = a.TaskId) 	       
 	       Where a.TaskId = @TaskId
 	         And (WorkStarted = 0 Or (WorkStarted = 1 And Datediff(Hour, WorkStartedTime, dbo.fnServer_CmnGetDate(GetUTCDate())) > 1))
 	       Order By Pending_Task_Id
 	  	 else
 	     Select Top 5000 ActualId,Pending_Task_Id,b.ET_Id,a.PU_Id,a.OldTimestamp,a.Misc
 	       From PendingTasks a WITH (NOLOCK)
 	  	  	  	 Join Tasks b on (b.TaskId = a.TaskId) 	       
 	       Where a.TaskId = @TaskId
 	         And (WorkStarted = 0 Or (WorkStarted = 1 And Datediff(Hour, WorkStartedTime, dbo.fnServer_CmnGetDate(GetUTCDate())) > 1))
 	       Order By Pending_Task_Id
  End
