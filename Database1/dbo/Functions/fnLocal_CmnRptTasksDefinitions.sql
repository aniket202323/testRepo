CREATE FUNCTION [dbo].[fnLocal_CmnRptTasksDefinitions]
(@strSKAreaEqId NVARCHAR (200) NULL, @strSKProdLineEqId NVARCHAR (800) NULL, @strSKWorkCellEqId NVARCHAR (MAX) NULL, @strTimeOption NVARCHAR (200) NULL, @dtmStartTime DATETIME NULL, @dtmEndTime DATETIME NULL, @strTaskFilter NVARCHAR (MAX) NULL, @strShowProjectedTasks NVARCHAR (3) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [TaskName]           NVARCHAR (200)   NULL,
        [TaskPriority]       INT              NULL,
        [TaskStartTime]      DATETIME         NULL,
        [TaskEndTime]        DATETIME         NULL,
        [RouteStatus]        NVARCHAR (100)   NULL,
        [Location]           NVARCHAR (200)   NULL,
        [FL]                 NVARCHAR (200)   NULL,
        [TaskId]             NVARCHAR (200)   NULL,
        [TaskStepId]         NVARCHAR (200)   NULL,
        [TaskInstanceId]     UNIQUEIDENTIFIER NULL,
        [TaskStepInstanceId] UNIQUEIDENTIFIER NULL,
        [TaskStepName]       NVARCHAR (200)   NULL,
        [TaskStepPriority]   INT              NULL,
        [TaskStepStartTime]  DATETIME         NULL,
        [TaskStepEndTime]    DATETIME         NULL,
        [StepRouteStatus]    NVARCHAR (100)   NULL,
        [StepLocation]       NVARCHAR (200)   NULL,
        [StepPersonnel]      NVARCHAR (200)   NULL,
        [StepFL]             NVARCHAR (200)   NULL,
        [RcIdx]              INT              IDENTITY (1, 1) NOT NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

