CREATE PROCEDURE dbo.spPurge_ExecuteTables(
@pgid int,
@timeSliceMinutes int,
@puid int,
@StartTime DateTime,
@totalAffected int out,
@DisableServCheck Int,
@MaxPendingTasks  Int
)
 AS
DECLARE 	 @affected 	  	  	 int,
 	  	 @quit 	  	  	  	 int,
 	  	 @name 	  	  	  	 sysname
IF @DisableServCheck = 0
 	 EXEC spPurge_CheckProcesses @quit out
ELSE
 	 SET @quit = 0
EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
SET @totalAffected=0
DECLARE  @tExecuteTables TABLE(TableName VarChar(100))
IF @puid Is NULL
BEGIN
 	 INSERT INTO @tExecuteTables(TableName)
 	  	 SELECT TableName
 	  	  	 FROM PurgeConfig_Detail
 	  	  	 WHERE Purge_Id = @pgid and PU_Id Is NUll and Var_Id Is Null and TableName Not in (select TableName From #FinishedTables)
END
ELSE
BEGIN
 	 INSERT INTO @tExecuteTables(TableName) SELECT 'Events'
 	 INSERT INTO @tExecuteTables(TableName) SELECT 'GB_RSum'
 	 INSERT INTO @tExecuteTables(TableName) SELECT 'Production_Starts'
 	 INSERT INTO @tExecuteTables(TableName) SELECT 'Timed_Event_Details'
 	 INSERT INTO @tExecuteTables(TableName) SELECT 'User_Defined_Events'
 	 INSERT INTO @tExecuteTables(TableName) SELECT 'Waste_Event_Details'
 	 INSERT INTO @tExecuteTables(TableName) SELECT 'OEEAggregation'
END
DECLARE TablesCursor cursor fast_forward local for select TableName from @tExecuteTables t order by TableName 
open TablesCursor
TablesCursorLoop:
fetch next from TablesCursor into @name
IF  @quit=0  and dateadd(n,@timeSliceMinutes,@StartTime)>getdate() AND @@fetch_status=0
BEGIN
 	 SET @affected=0
 	 EXEC spPurge_ExecuteTable @pgid,@timeSliceMinutes,@puid,@name,@StartTime,@affected out,@DisableServCheck,@MaxPendingTasks
 	 IF @affected = 0 INSERT INTO #FinishedTables(TableName) SELECT @name
 	 SET @totalAffected=@totalAffected+@affected
 	 IF @DisableServCheck = 0
 	  	 EXEC spPurge_CheckProcesses @quit out
 	 EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
 	 GOTO TablesCursorLoop
end
close TablesCursor
deallocate TablesCursor
