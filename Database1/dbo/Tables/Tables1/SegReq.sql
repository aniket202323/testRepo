CREATE TABLE [dbo].[SegReq] (
    [ProductSegmentS95Id]   NVARCHAR (50)    NULL,
    [ProcessSegmentS95Id]   NVARCHAR (50)    NULL,
    [ProcessSegmentVersion] BIGINT           NULL,
    [S95Id]                 NVARCHAR (50)    NULL,
    [r_Order]               INT              NULL,
    [IsTopOfHierarchy]      BIT              NULL,
    [EarliestStartTime]     DATETIME         NULL,
    [LatestEndTime]         DATETIME         NULL,
    [DurationUnitOfMeasure] NVARCHAR (50)    NULL,
    [IsMaster]              BIT              NULL,
    [Duration]              FLOAT (53)       NULL,
    [WorkType]              NVARCHAR (25)    NULL,
    [SegReqId]              UNIQUEIDENTIFIER NOT NULL,
    [Description]           NVARCHAR (255)   NULL,
    [S95Type]               NVARCHAR (50)    NULL,
    [LastModifiedTime]      DATETIME         NULL,
    [LastModifiedBy]        NVARCHAR (255)   NULL,
    [Version]               BIGINT           NULL,
    [WorkRequestId]         UNIQUEIDENTIFIER NOT NULL,
    [ProcSegId]             UNIQUEIDENTIFIER NULL,
    [EquipmentId]           UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SegReqId] ASC, [WorkRequestId] ASC),
    CONSTRAINT [SegReq_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]),
    CONSTRAINT [SegReq_ProcSeg_Relation1] FOREIGN KEY ([ProcSegId]) REFERENCES [dbo].[ProcSeg] ([ProcSegId]),
    CONSTRAINT [SegReq_WorkRequest_Relation1] FOREIGN KEY ([WorkRequestId]) REFERENCES [dbo].[WorkRequest] ([WorkRequestId])
);


GO
ALTER TABLE [dbo].[SegReq] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_SegReq_ProductSegmentS95Id]
    ON [dbo].[SegReq]([ProductSegmentS95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SegReq_ProcessSegmentS95Id]
    ON [dbo].[SegReq]([ProcessSegmentS95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SegReq_S95Id]
    ON [dbo].[SegReq]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SegReq_LastModifiedTime]
    ON [dbo].[SegReq]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegReq_WorkRequestId]
    ON [dbo].[SegReq]([WorkRequestId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegReq_ProcSegId]
    ON [dbo].[SegReq]([ProcSegId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegReq_EquipmentId]
    ON [dbo].[SegReq]([EquipmentId] ASC);

