﻿CREATE FUNCTION [dbo].[fnLocal_LEDS_DowntimeRawData]
(@p_intPUId INT NULL, @p_vchStartDateTime VARCHAR (25) NULL, @p_vchEndDateTime VARCHAR (25) NULL, @p_intSplitRecords INT NULL, @p_intIncludeShift INT NULL, @p_intIncludeProductionDay INT NULL, @p_intIncludeProduct INT NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [RcdIdx]                       INT           IDENTITY (1, 1) NOT NULL,
        [PLId]                         INT           NULL,
        [PUId]                         INT           NULL,
        [ProductionPUId]               INT           NULL,
        [EventCrewSchedulePUId]        INT           NULL,
        [EventShift]                   VARCHAR (25)  NULL,
        [EventTeam]                    VARCHAR (25)  NULL,
        [EventProductionDayId]         INT           NULL,
        [EventProductionDay]           VARCHAR (25)  NULL,
        [EventProductionStatusId]      INT           NULL,
        [EventProductionStatus]        VARCHAR (50)  NULL,
        [ProdId]                       INT           NULL,
        [LEDSId]                       INT           NULL,
        [UPTimeStart]                  VARCHAR (25)  NULL,
        [UPTimeEnd]                    VARCHAR (25)  NULL,
        [UPTimeDurationInSec]          INT           NULL,
        [LEDSStart]                    VARCHAR (25)  NULL,
        [LEDSEnd]                      VARCHAR (25)  NULL,
        [LEDSStartForRpt]              VARCHAR (25)  NULL,
        [LEDSEndForRpt]                VARCHAR (25)  NULL,
        [LEDSDurationInSec]            INT           NULL,
        [LEDSDurationInSecForRpt]      INT           NULL,
        [LEDSCount]                    INT           NULL,
        [LEDSParentId]                 INT           NULL,
        [CauseRL1Id]                   INT           NULL,
        [CauseRL2Id]                   INT           NULL,
        [CauseRL3Id]                   INT           NULL,
        [CauseRL4Id]                   INT           NULL,
        [TreeNodeId]                   INT           NULL,
        [ActionTreeId]                 INT           NULL,
        [Action1Id]                    INT           NULL,
        [Action2Id]                    INT           NULL,
        [Action3Id]                    INT           NULL,
        [Action4Id]                    INT           NULL,
        [ActionTreeNodeId]             INT           NULL,
        [CatDTSched]                   VARCHAR (50)  NULL,
        [CatDTType]                    VARCHAR (50)  NULL,
        [CatDTGroup]                   VARCHAR (50)  NULL,
        [CatDTMach]                    VARCHAR (50)  NULL,
        [CatDTClass]                   VARCHAR (50)  NULL,
        [CatDTClassCause]              VARCHAR (50)  NULL,
        [CatDTClassAction]             VARCHAR (50)  NULL,
        [FaultId]                      INT           NULL,
        [TEFault_Name]                 VARCHAR (100) NULL,
        [LEDSCommentId]                INT           NULL,
        [EventSplitFactor]             FLOAT (53)    NULL,
        [EventSplitFlag]               INT           NULL,
        [EventSplitShiftFlag]          INT           DEFAULT ((0)) NULL,
        [EventSplitProductionDayFlag]  INT           DEFAULT ((0)) NULL,
        [EventSplitProductFlag]        INT           DEFAULT ((0)) NULL,
        [EventSplitLineStatusFlag]     INT           DEFAULT ((0)) NULL,
        [UpTimeSplitShiftFlag]         INT           DEFAULT ((0)) NULL,
        [UptimeSplitProductionDayFlag] INT           DEFAULT ((0)) NULL,
        [UptimeSplitProductFlag]       INT           DEFAULT ((0)) NULL,
        [UptimeSplitLineStatusFlag]    INT           DEFAULT ((0)) NULL,
        [OverlapFlag]                  INT           DEFAULT ((0)) NULL,
        [OverlapSequence]              INT           DEFAULT ((0)) NULL,
        [OverlapRcdFlag]               INT           DEFAULT ((0)) NULL,
        [ErrorCode]                    INT           NULL,
        [Error]                        VARCHAR (150) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

