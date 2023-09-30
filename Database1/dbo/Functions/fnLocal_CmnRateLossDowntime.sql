CREATE FUNCTION [dbo].[fnLocal_CmnRateLossDowntime]
(@intPUId INT NULL, @dtmStartTime DATETIME NULL, @dtmEndTime DATETIME NULL, @intSplitFlag INT NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [PUId]                  INT            NULL,
        [AlarmId]               INT            NULL,
        [AlamrDesc]             NVARCHAR (200) NULL,
        [AlCause1]              NVARCHAR (200) NULL,
        [AlCause2]              NVARCHAR (200) NULL,
        [AlCause3]              NVARCHAR (200) NULL,
        [AlCause4]              NVARCHAR (200) NULL,
        [AlAction1]             NVARCHAR (200) NULL,
        [AlAction2]             NVARCHAR (200) NULL,
        [AlAction3]             NVARCHAR (200) NULL,
        [AlAction4]             NVARCHAR (200) NULL,
        [AlComment]             TEXT           NULL,
        [VarId]                 INT            NULL,
        [StartTime]             DATETIME       NULL,
        [EndTime]               DATETIME       NULL,
        [ActualRate]            FLOAT (53)     NULL,
        [Duration]              FLOAT (53)     NULL,
        [Target]                FLOAT (53)     NULL,
        [ProdId]                INT            NULL,
        [ProdDesc]              NVARCHAR (200) NULL,
        [Shift]                 NVARCHAR (50)  NULL,
        [CrewDesc]              NVARCHAR (50)  NULL,
        [ProdDay]               DATETIME       NULL,
        [NPTId]                 INT            NULL,
        [NPTDesc]               NVARCHAR (50)  NULL,
        [RateLoss]              FLOAT (53)     NULL,
        [OverlapFlagShift]      INT            NULL,
        [OverlapSequence]       INT            NULL,
        [OverlapRcdFlag]        INT            NULL,
        [SplitFlagShift]        INT            NULL,
        [SplitFlagLineStatus]   INT            NULL,
        [OverlapFlagLineStatus] INT            NULL,
        [Idx]                   INT            IDENTITY (1, 1) NOT NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

