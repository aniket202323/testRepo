CREATE TABLE [dbo].[Local_S95OEProductionScheduleDownloadStateLogic] (
    [UseCaseId]          INT          NOT NULL,
    [UseCaseActive]      INT          NOT NULL,
    [ERPOrderStatus]     VARCHAR (50) NULL,
    [ERPOrderStatusId]   INT          NULL,
    [FlgMESOrderExisted] INT          NULL,
    [FlgDataChange]      INT          NULL,
    [FlgActiveBefore]    INT          NULL,
    [PPCurrentStatusStr] VARCHAR (50) NULL,
    [FlgBOMMissing]      INT          NULL,
    [PPCreateAction]     INT          NULL,
    [PPCreateStatusStr]  VARCHAR (50) NULL,
    [PPUpdateAction]     INT          NULL,
    [PPUpdateStatusStr]  VARCHAR (50) NULL,
    [FlgAllowDataChange] INT          NULL,
    [FlgAlert]           INT          NULL,
    [ErrCode]            INT          NULL,
    [FlgLockedData]      INT          NULL,
    [FlgUnlockedData]    INT          NULL
);

