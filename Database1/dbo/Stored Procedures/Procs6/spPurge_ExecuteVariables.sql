CREATE PROCEDURE dbo.spPurge_ExecuteVariables(
@pgid int,
@timeSliceMinutes int,
@puid int,
@StartTime DateTime,
@totalAffected int out,
@DisableServCheck Int,
@MaxPendingTasks  Int
)
 AS
declare @affected 	 int,
 	  	 @quit 	  	 int,
 	  	 @varid 	  	 int
DECLARE @tExecuteVariables Table (varid int)
set @totalAffected=0
INSERT INTO @tExecuteVariables (varid)
 	 SELECT 	 DISTINCT Var_Id
 	 FROM PurgeConfig_Detail
 	 WHERE Purge_Id=@pgid
IF @DisableServCheck = 0
 	 EXEC spPurge_CheckProcesses @quit out
ELSE
 	 SET @quit = 0
EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
declare VariablesCursor cursor fast_forward for select varid from @tExecuteVariables t
open VariablesCursor
VariablesCursorLOOP:
fetch next from VariablesCursor into @varid
IF @@fetch_status=0 and @quit=0 and dateadd(n,@timeSliceMinutes,@StartTime)>getdate()
begin
 	 exec spPurge_ExecuteVariable @pgid,@timeSliceMinutes,@puid,@varid,@StartTime,@affected out,@DisableServCheck,@MaxPendingTasks
 	 set @totalAffected=@totalAffected+@affected
 	 IF @DisableServCheck = 0
 	  	 exec spPurge_CheckProcesses @quit out
 	 EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
 	 GOTO VariablesCursorLOOP
end
close VariablesCursor
deallocate VariablesCursor
