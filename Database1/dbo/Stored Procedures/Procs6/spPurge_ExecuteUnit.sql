CREATE PROCEDURE dbo.spPurge_ExecuteUnit(
@pgid int,
@timeSliceMinutes int,
@puid int,
@StartTime DateTime,
@totalAffected int out,
@DisableServCheck Int,
@MaxPendingTasks  Int) 
AS
DECLARE @affected 	 int,
 	  	 @quit 	  	 int,
 	  	 @name 	  	 sysname
set @totalAffected=0
DECLARE  @tExecuteUnit table (TableName VarChar(100))
IF EXISTS(Select * FROM PurgeConfig_Detail 	 WHERE Purge_Id = @pgid and PU_Id = @puid and Var_Id Is Null)
BEGIN
 	 INSERT into @tExecuteUnit(TableName) Values('Tables')
END
IF EXISTS(Select * FROM PurgeConfig_Detail 	 WHERE Purge_Id = @pgid and PU_Id = @puid and Var_Id Is Not Null)
BEGIN
 	 insert into @tExecuteUnit(TableName) values ('Variables')
END
IF @DisableServCheck = 0
 	 EXEC spPurge_CheckProcesses @quit out
ELSE
 	 SET @quit = 0
EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
declare UnitCursor cursor fast_forward local for select TableName from @tExecuteUnit t
open UnitCursor
UnitCursorLoop:
fetch next from UnitCursor into @name
IF @@fetch_status=0 And @quit=0  and dateadd(n,@timeSliceMinutes,@StartTime)>getdate() 
BEGIN
 	 set @affected=0
 	 if @name='Tables'
 	  	 exec spPurge_ExecuteTables @pgid,@timeSliceMinutes,@puid,@StartTime,@affected out,@DisableServCheck,@MaxPendingTasks
 	 else
 	  	 exec spPurge_ExecuteVariables @pgid,@timeSliceMinutes,@puid,@StartTime,@affected out,@DisableServCheck,@MaxPendingTasks
 	 set @totalAffected=@totalAffected+@affected
 	 IF @DisableServCheck = 0
 	  	 exec spPurge_CheckProcesses @quit out
 	 EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
 	 GOTO UnitCursorLoop
end
close UnitCursor
deallocate UnitCursor
