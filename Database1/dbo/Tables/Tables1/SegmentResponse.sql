CREATE TABLE [dbo].[SegmentResponse] (
    [S95Id]                   NVARCHAR (255)   NULL,
    [Depth]                   INT              NULL,
    [ProcessSegmentS95Id]     NVARCHAR (255)   NULL,
    [ProcessSegmentVersion]   BIGINT           NULL,
    [WorkType]                NVARCHAR (25)    NULL,
    [StartTime]               DATETIME         NULL,
    [EndTime]                 DATETIME         NULL,
    [SegmentResponseId]       UNIQUEIDENTIFIER NOT NULL,
    [Description]             NVARCHAR (255)   NULL,
    [S95Type]                 NVARCHAR (50)    NULL,
    [LastModifiedTime]        DATETIME         NULL,
    [LastModifiedBy]          NVARCHAR (255)   NULL,
    [Version]                 BIGINT           NULL,
    [WorkResponseId]          UNIQUEIDENTIFIER NULL,
    [ParentSegmentResponseId] UNIQUEIDENTIFIER NULL,
    [ProcSegId]               UNIQUEIDENTIFIER NULL,
    [EquipmentId]             UNIQUEIDENTIFIER NULL,
    [SegReqId]                UNIQUEIDENTIFIER NULL,
    [WorkRequestId]           UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SegmentResponseId] ASC),
    CONSTRAINT [SegmentResponse_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]) ON DELETE SET NULL,
    CONSTRAINT [SegmentResponse_ProcSeg_Relation1] FOREIGN KEY ([ProcSegId]) REFERENCES [dbo].[ProcSeg] ([ProcSegId]),
    CONSTRAINT [SegmentResponse_SegmentResponse_Relation1] FOREIGN KEY ([ParentSegmentResponseId]) REFERENCES [dbo].[SegmentResponse] ([SegmentResponseId]),
    CONSTRAINT [SegmentResponse_SegReq_Relation1] FOREIGN KEY ([SegReqId], [WorkRequestId]) REFERENCES [dbo].[SegReq] ([SegReqId], [WorkRequestId]),
    CONSTRAINT [SegmentResponse_WorkResponse_Relation1] FOREIGN KEY ([WorkResponseId]) REFERENCES [dbo].[WorkResponse] ([WorkResponseId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SegmentResponse_ProcessSegmentS95Id]
    ON [dbo].[SegmentResponse]([ProcessSegmentS95Id] ASC)
    INCLUDE([WorkResponseId]);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentResponse_WorkResponseId]
    ON [dbo].[SegmentResponse]([WorkResponseId] ASC, [SegmentResponseId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SegmentResponse_LastModifiedTime]
    ON [dbo].[SegmentResponse]([LastModifiedTime] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SegmentResponse_S95Id_WorkResponseId_ParentSegmentResponseId]
    ON [dbo].[SegmentResponse]([S95Id] ASC, [WorkResponseId] ASC, [ParentSegmentResponseId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentResponse_WorkRequestId]
    ON [dbo].[SegmentResponse]([WorkRequestId] ASC)
    INCLUDE([S95Id], [StartTime], [EndTime], [SegmentResponseId], [Description], [SegReqId]);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentResponse_ParentSegmentResponseId]
    ON [dbo].[SegmentResponse]([ParentSegmentResponseId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentResponse_ProcSegId]
    ON [dbo].[SegmentResponse]([ProcSegId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentResponse_EquipmentId]
    ON [dbo].[SegmentResponse]([EquipmentId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentResponse_SegReqId_WorkRequestId]
    ON [dbo].[SegmentResponse]([SegReqId] ASC, [WorkRequestId] ASC);

