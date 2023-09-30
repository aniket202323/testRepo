CREATE PROCEDURE dbo.spPurge_ExecuteUnits(
@pgid int,
@timeSliceMinutes int,
@StartTime DateTime,
@totalAffected int out,
@DisableServCheck Int,
@MaxPendingTasks Int
)
 AS
DECLARE 	 @affected 	 int,
 	  	 @quit 	  	 int,
 	  	 @puid 	  	 int
DECLARE @tEUnts TABLE(puid int)
SET @totalAffected=0
INSERT INTO @tEUnts
 SELECT Distinct PU_Id
 	 FROM PurgeConfig_Detail 
 	 WHERE  Purge_Id=@pgid AND PU_Id Is not Null
IF @DisableServCheck = 0
 	 EXEC spPurge_CheckProcesses @quit out
ELSE
 	 SET @quit = 0
 	 
EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
DECLARE UnitsCursor cursor fast_forward local for select puid from @tEUnts t
open UnitsCursor
UnitsCursorLoop:
fetch next from UnitsCursor into @puid
IF @@fetch_status=0 And @quit=0 And dateadd(n,@timeSliceMinutes,@StartTime)>getdate()
BEGIN
 	 set @affected=null
 	 exec spPurge_ExecuteUnit @pgid,@timeSliceMinutes,@puid,@StartTime,@affected out,@DisableServCheck,@MaxPendingTasks
 	 set @totalAffected=@totalAffected+@affected
 	 IF @DisableServCheck = 0
 	  	 exec spPurge_CheckProcesses @quit out
 	 EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
 	 GOTO UnitsCursorLoop
END
close UnitsCursor
deallocate UnitsCursor
