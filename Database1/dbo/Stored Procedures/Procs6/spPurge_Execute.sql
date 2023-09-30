CREATE PROCEDURE dbo.spPurge_Execute(
 	 @pgid int,
 	 @DisableServCheck Int = 0,
 	 @MaxPendingTasks Int = 0
) AS
SET NOCOUNT ON
declare @contextinfo varbinary(128),@originalcontextinfo varbinary(128)
set @originalcontextinfo = cast('spPurge_Execute' as varbinary(128))
set @contextinfo = cast('DataPurge' as varbinary(128))
SET context_info @contextinfo;
DECLARE @dt 	  	  	  	  	 DATETIME,
 	  	 @retention 	  	  	 INT,
 	  	 @elementPerBatch 	 INT,
 	  	 @timeSliceMinutes 	 INT,
 	  	 @affected 	  	  	 INT,
 	  	 @time 	  	  	  	 INT,
 	  	 @again 	  	  	  	 BIT,
 	  	 @elements 	  	  	 INT,
 	  	 @totalAffected 	  	 INT,
 	  	 @quit 	  	  	  	 INT,
 	  	 @name 	  	  	  	 sysname,
 	  	 @stepTime 	  	  	 DATETIME,
 	  	 @config 	  	  	  	 varchar(255),
 	  	 @PurgeDesc 	  	  	 VarChar(100),
 	  	 @RunId 	  	  	  	 Int
CREATE TABLE #FinishedTables (TableName VarChar(100) Collate database_default)
SET @dt=getdate()
IF @MaxPendingTasks IS NULL
 	 SET @MaxPendingTasks = 0
If @DisableServCheck Is Null
 	 SET @DisableServCheck = 0
 	 
IF @DisableServCheck = 0
 	 EXEC spPurge_CheckProcesses @quit out
ELSE
 	 SET @quit = 0
SET @totalAffected=0
SET @elements=0
DECLARE @AuditId integer 
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
VALUES (2,1,'spPurge_Execute',convert(varchar(10),@pgid),  getdate())
SELECT @AuditId = Scope_Identity()
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 SELECT  2,1,'Purge Details',
 	 'Name:' + ISNULL(TableName,'Null') + ',' + 
 	 'Batch:' + ISNULL(Convert(varchar(10),ElementPerBatch),'Null') + ',' + 
 	 'PurgeId:' + ISNULL(Convert(varchar(10),Purge_Id),'Null') + ',' + 
 	 'Retension:' + ISNULL(Convert(varchar(10),RetentionMonths),'Null') + ',' + 
 	 'PUID:' + ISNULL(Convert(varchar(10),PU_Id),'Null') + ',' + 
 	 'VarId:' + ISNULL(Convert(varchar(10),Var_Id),'Null')
 	 ,  getdate()
 	 FROM PurgeConfig_Detail
 	 WHERE Purge_Id = @pgid
SELECT @time = NULL
SELECT @time = TimeSliceMinutes,@PurgeDesc = Purge_Desc
 	 FROM PurgeConfig
 	 WHERE Purge_Id = @pgid
SET @config=' Job Started [' + @PurgeDesc + ']'
SET @RunId = -1
EXEC spPurge_SetResult @config,0,@RunId OutPut
EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
SELECT @timeSliceMinutes = Coalesce(@time,10080) -- Max 1 week
IF @timeSliceMinutes = 0 
 	 SET @timeSliceMinutes = 10080
SET @again=1
WHILE @quit=0 and @again=1 and dateadd(n,@timeSliceMinutes,@dt)>getdate()
BEGIN
 	 SET @again=0
 	 SET @affected=null
 	 WHILE @quit=0 and dateadd(n,@timeSliceMinutes,@dt)>getdate() and (@affected > 0 or @affected is null)
 	 BEGIN
 	  	 SET @affected=0
 	  	 IF EXISTS(SELECT TOP 1 * FROM PurgeConfig_Detail WHERE PU_Id Is NULL And Var_Id IS NULL AND Purge_Id = @pgid)
 	  	 BEGIN
 	  	  	 EXEC spPurge_ExecuteTables @pgid,@timeSliceMinutes,null,@dt,@affected out,@DisableServCheck,@MaxPendingTasks
 	  	  	 SET @totalAffected=@totalAffected+@affected
 	  	  	 IF @affected > 0 SET @again=1
 	  	 END
 	  	 IF EXISTS(SELECT TOP 1 * FROM PurgeConfig_Detail WHERE (PU_Id Is Not NULL OR Var_Id IS NOT NULL) AND Purge_Id = @pgid)
 	  	 BEGIN
 	  	  	 EXEC spPurge_ExecuteUnits @pgid,@timeSliceMinutes,@dt,@affected out,@DisableServCheck,@MaxPendingTasks -- Local/Unit
 	  	  	 SET @totalAffected=@totalAffected+@affected
 	  	  	 IF @affected > 0 SET @again=1
 	  	 END
 	  	 IF @DisableServCheck = 0
 	  	  	 EXEC spPurge_CheckProcesses @quit out
 	  	 EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
 	 END
 	 IF @affected > 0 
 	  	 SET @again=1
END
IF @totalAffected > 0 
BEGIN
 	 SET @config=' Job Complete [' + @PurgeDesc + ']' 
 	 EXEC spPurge_SetResult @config,@totalAffected,@RunId
END
ELSE IF @quit>0 
 	  	 BEGIN
 	  	  	 SET @config='Proficy Services Detected. ['+@PurgeDesc+'] aborted.'
 	  	  	 EXEC spPurge_SetResult @config,0,@RunId
 	  	  	 SET @config=' Job Complete [' + @PurgeDesc + ']' 
 	  	  	 EXEC spPurge_SetResult @config,@totalAffected,@RunId
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SET @config= 'Nothing found to purge.'
 	  	  	 EXEC spPurge_SetResult @config,@totalAffected,@RunId
 	  	  	 SET @config=' Job Complete [' + @PurgeDesc + ']' 
 	  	  	 EXEC spPurge_SetResult @config,@totalAffected,@RunId
 	  	 END
DROP TABLE #FinishedTables 
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
 WHERE Audit_Trail_Id = @AuditId
 SET context_info @originalcontextinfo
