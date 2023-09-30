﻿CREATE FUNCTION [dbo].[fnLocal_CmnRptDowntimeDetailByEquipment]
(@strAreaId NVARCHAR (200) NULL, @strProdLineId NVARCHAR (800) NULL, @strWorkCellId NVARCHAR (MAX) NULL, @vchTimeOption NVARCHAR (50) NULL, @dtmStartDateTime DATETIME NULL, @dtmEndDateTime DATETIME NULL, @vchSplitLogicalRcd NVARCHAR (20) NULL, @vchExcludeNPT NVARCHAR (3) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [DowntimeStart]      DATETIME       NULL,
        [DowntimeEnd]        DATETIME       NULL,
        [DownTime]           FLOAT (53)     NULL,
        [UpTime]             FLOAT (53)     NULL,
        [DeptId]             INT            NULL,
        [DeptDesc]           NVARCHAR (100) NULL,
        [PLId]               INT            NULL,
        [PLDesc]             NVARCHAR (100) NULL,
        [PUId]               INT            NULL,
        [PUDesc]             NVARCHAR (100) NULL,
        [SourcePUId]         INT            NULL,
        [DowntimeTreeId]     INT            NULL,
        [TEFaultId]          INT            NULL,
        [TEFaultValue]       NVARCHAR (100) NULL,
        [SourcePUDesc]       NVARCHAR (100) NULL,
        [EquipmentArea]      NVARCHAR (100) NULL,
        [FLDesc]             NVARCHAR (100) NULL,
        [DelayRL1Id]         INT            NULL,
        [DelayRL2Id]         INT            NULL,
        [DelayRL3Id]         INT            NULL,
        [DelayRL4Id]         INT            NULL,
        [EventReasonName1]   NVARCHAR (100) NULL,
        [EventReasonName2]   NVARCHAR (100) NULL,
        [EventReasonName3]   NVARCHAR (100) NULL,
        [EventReasonName4]   NVARCHAR (100) NULL,
        [ActionTreeId]       INT            NULL,
        [ActionL1Id]         INT            NULL,
        [ActionL2Id]         INT            NULL,
        [ActionL3Id]         INT            NULL,
        [ActionL4Id]         INT            NULL,
        [ActionReasonName1]  NVARCHAR (100) NULL,
        [ActionReasonName2]  NVARCHAR (100) NULL,
        [ActionReasonName3]  NVARCHAR (100) NULL,
        [ActionReasonName4]  NVARCHAR (100) NULL,
        [CauseCommentId]     INT            NULL,
        [CommentIdList]      NVARCHAR (MAX) NULL,
        [ShiftDesc]          NVARCHAR (50)  NULL,
        [CrewSchedulePUId]   INT            NULL,
        [CrewDesc]           NVARCHAR (50)  NULL,
        [ProductionDay]      DATETIME       NULL,
        [ProdStatusId]       INT            NULL,
        [ProdStatus]         NVARCHAR (50)  NULL,
        [ProdId]             INT            NULL,
        [ProdCode]           NVARCHAR (50)  NULL,
        [ProdDesc]           NVARCHAR (200) NULL,
        [ExecPath]           NVARCHAR (100) NULL,
        [StopClass]          NVARCHAR (100) NULL,
        [DelayCategoryDesc]  NVARCHAR (100) NULL,
        [SplitEventFlag]     NVARCHAR (1)   NULL,
        [ConstraintWorkCell] INT            NULL,
        [Breakdown]          INT            NULL,
        [DetId]              INT            NULL,
        [ParentDetId]        INT            NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

