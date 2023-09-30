CREATE TABLE [dbo].[Local_DebugTrigger] (
    [id]           INT            IDENTITY (1, 1) NOT NULL,
    [OldPUId]      INT            NULL,
    [OldStartTime] DATETIME       NULL,
    [OldEndTime]   DATETIME       NULL,
    [PUId]         INT            NULL,
    [StartTime]    DATETIME       NULL,
    [EndTime]      DATETIME       NULL,
    [NPDetId]      INT            NULL,
    [ReasonLevel1] INT            NULL,
    [UpdateStatus] NVARCHAR (50)  NULL,
    [comment]      NVARCHAR (500) NULL
);

