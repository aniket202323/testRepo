CREATE PROCEDURE dbo.spPurge_CheckPendingTasks(@MaxCount Int, @Quit int out) AS
DECLARE @CurrentCount Int
SELECT @Quit = Coalesce(@Quit,0)
IF @Quit != 0
 	 RETURN
SET @Quit=0
IF @MaxCount = 0 
 	 RETURN
SELECT 	 @CurrentCount = count(*) 
 	 FROM 	 PendingTasks
IF  @CurrentCount > @MaxCount
BEGIN
 	 SET @Quit = 1
 	 exec spPurge_SetResult 'Too many Pending Tasks Job Stopping',0,Null
END
 	 
