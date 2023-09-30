CREATE FUNCTION [dbo].[fnLocal_LEDS_ProductionRawData_12_PR]
(@p_intPLId INT NULL, @p_vchStartDateTime VARCHAR (25) NULL, @p_vchEndDateTime VARCHAR (25) NULL, @p_intSplitRecords INT NULL, @p_intIncludeShift INT NULL, @p_intIncludeProductionDay INT NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [RcdIdx]                         INT           IDENTITY (1, 1) NOT NULL,
        [PLId]                           INT           NULL,
        [EventCrewSchedulePUId]          INT           NULL,
        [EventShift]                     VARCHAR (25)  NULL,
        [EventTeam]                      VARCHAR (25)  NULL,
        [EventProductionDayId]           INT           NULL,
        [EventProductionDay]             VARCHAR (25)  NULL,
        [EventId]                        INT           NULL,
        [EventPUId]                      INT           NULL,
        [EventNumber]                    VARCHAR (100) NULL,
        [EventStart]                     VARCHAR (25)  NULL,
        [EventEnd]                       VARCHAR (25)  NULL,
        [EventStartForRpt]               VARCHAR (25)  NULL,
        [EventEndForRpt]                 VARCHAR (25)  NULL,
        [EventProductionTimeInSec]       INT           NULL,
        [EventProductionTimeInSecForRpt] INT           NULL,
        [EventProdId]                    INT           NULL,
        [EventPSProdId]                  INT           NULL,
        [EventAppliedProdId]             INT           NULL,
        [EventProductionStatusVarId]     INT           NULL,
        [EventProductionStatus]          VARCHAR (50)  NULL,
        [EventAdjustedCasesVarId]        INT           NULL,
        [EventAdjustedCases]             FLOAT (53)    NULL,
        [EventStatCaseConvFactorVarId]   INT           NULL,
        [EventStatCaseConvFactor]        FLOAT (53)    NULL,
        [EventAdjustedUnitsVarId]        INT           NULL,
        [EventAdjustedUnits]             FLOAT (53)    NULL,
        [EventTargetRateVarId]           INT           NULL,
        [EventTargetRatePerMin]          FLOAT (53)    NULL,
        [EventActualRateVarId]           INT           NULL,
        [EventActualRatePerMin]          FLOAT (53)    NULL,
        [EventUnitsPerCaseVarId]         INT           NULL,
        [EventUnitsPerCase]              FLOAT (53)    NULL,
        [EventScheduledTimeVarId]        INT           NULL,
        [EventScheduledTimeInSec]        FLOAT (53)    NULL,
        [EventIdealRateVarId]            INT           NULL,
        [EventIdealRatePerMin]           FLOAT (53)    NULL,
        [EventSplitFactor]               FLOAT (53)    NULL,
        [EventSplitFlag]                 INT           NULL,
        [EventSplitShiftFlag]            INT           DEFAULT ((0)) NULL,
        [EventSplitProductionDayFlag]    INT           DEFAULT ((0)) NULL,
        [OverlapFlagShift]               INT           DEFAULT ((0)) NULL,
        [OverlapFlagProductionDay]       INT           DEFAULT ((0)) NULL,
        [OverlapSequence]                INT           DEFAULT ((0)) NULL,
        [OverlapRcdFlag]                 INT           DEFAULT ((0)) NULL,
        [ErrorCode]                      INT           NULL,
        [Error]                          VARCHAR (150) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

