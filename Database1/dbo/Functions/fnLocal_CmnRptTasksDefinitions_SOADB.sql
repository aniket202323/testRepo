CREATE FUNCTION [dbo].[fnLocal_CmnRptTasksDefinitions_SOADB]
(@strSKAreaEqId NVARCHAR (200) NULL, @strSKProdLineEqId NVARCHAR (200) NULL, @strSKWorkCellEqId NVARCHAR (200) NULL, @strTimeOption NVARCHAR (200) NULL, @dtmStartTime DATETIME NULL, @dtmEndTime DATETIME NULL, @strTaskFilter NVARCHAR (MAX) NULL, @strShowProjectedTasks NVARCHAR (3) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [TaskName]             NVARCHAR (200)   NULL,
        [TaskPriority]         INT              NULL,
        [TaskStartTime]        DATETIME         NULL,
        [TaskEndTime]          DATETIME         NULL,
        [RouteStatus]          NVARCHAR (100)   NULL,
        [PlannedDuration]      INT              NULL,
        [ActualDuration]       INT              NULL,
        [Location]             NVARCHAR (200)   NULL,
        [PlannedStart]         DATETIME         NULL,
        [FL]                   NVARCHAR (200)   NULL,
        [TaskDefId]            NVARCHAR (200)   NULL,
        [StepDefId]            NVARCHAR (200)   NULL,
        [WfTaskInstId]         UNIQUEIDENTIFIER NULL,
        [WfTaskStepInstId]     UNIQUEIDENTIFIER NULL,
        [TaskStepName]         NVARCHAR (200)   NULL,
        [TaskStepPriority]     INT              NULL,
        [TaskStepStartTime]    DATETIME         NULL,
        [TaskStepEndTime]      DATETIME         NULL,
        [StepRouteStatus]      NVARCHAR (100)   NULL,
        [StepPlannedDuration]  INT              NULL,
        [StepActualDuration]   INT              NULL,
        [StepLocation]         NVARCHAR (200)   NULL,
        [StepPersonnel]        NVARCHAR (200)   NULL,
        [StepPlannedStart]     NVARCHAR (24)    NULL,
        [StepTaskType]         NVARCHAR (200)   NULL,
        [StepFL]               NVARCHAR (200)   NULL,
        [StepDowntimeRequired] NVARCHAR (10)    NULL,
        [StepProductRelease]   NVARCHAR (10)    NULL,
        [StepDefect]           NVARCHAR (10)    DEFAULT ('False') NULL,
        [StepOnTime]           NVARCHAR (10)    NULL,
        [StepOnTarget]         NVARCHAR (10)    DEFAULT ('False') NULL,
        [RcIdx]                INT              IDENTITY (1, 1) NOT NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

