CREATE TABLE [historyservice].[SegmentActuals] (
    [RowId]               BIGINT         IDENTITY (1, 1) NOT NULL,
    [MaterialLotActualId] BIGINT         NULL,
    [Name]                NVARCHAR (255) NULL,
    [SegmentActualId]     BIGINT         NULL,
    [SegmentId]           BIGINT         NULL,
    [WorkOrderId]         BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([RowId] ASC),
    CONSTRAINT [U_SGMNTLS_SEGMENTACTUALID] UNIQUE NONCLUSTERED ([SegmentActualId] ASC)
);

