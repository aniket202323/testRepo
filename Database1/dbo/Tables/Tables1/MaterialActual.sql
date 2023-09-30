CREATE TABLE [dbo].[MaterialActual] (
    [S95Id]                 NVARCHAR (50)    NULL,
    [QuantityUnitOfMeasure] NVARCHAR (50)    NULL,
    [Quantity]              FLOAT (53)       NULL,
    [r_Use]                 NVARCHAR (255)   NULL,
    [StartTime]             DATETIME         NULL,
    [EndTime]               DATETIME         NULL,
    [MaterialActualId]      UNIQUEIDENTIFIER NOT NULL,
    [Description]           NVARCHAR (255)   NULL,
    [S95Type]               NVARCHAR (50)    NULL,
    [LastModifiedTime]      DATETIME         NULL,
    [LastModifiedBy]        NVARCHAR (255)   NULL,
    [Version]               BIGINT           NULL,
    [MaterialDefinitionId]  UNIQUEIDENTIFIER NULL,
    [MaterialClassName]     NVARCHAR (200)   NULL,
    [MaterialLotId]         UNIQUEIDENTIFIER NULL,
    [MaterialSublotId]      UNIQUEIDENTIFIER NULL,
    [SegmentResponseId]     UNIQUEIDENTIFIER NULL,
    [MaterialSpec_SegReqId] UNIQUEIDENTIFIER NULL,
    [SegReqId]              UNIQUEIDENTIFIER NULL,
    [WorkRequestId]         UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([MaterialActualId] ASC),
    CONSTRAINT [MaterialActual_MaterialClass_Relation1] FOREIGN KEY ([MaterialClassName]) REFERENCES [dbo].[MaterialClass] ([MaterialClassName]),
    CONSTRAINT [MaterialActual_MaterialDefinition_Relation1] FOREIGN KEY ([MaterialDefinitionId]) REFERENCES [dbo].[MaterialDefinition] ([MaterialDefinitionId]),
    CONSTRAINT [MaterialActual_MaterialLot_Relation1] FOREIGN KEY ([MaterialLotId]) REFERENCES [dbo].[MaterialLot] ([MaterialLotId]),
    CONSTRAINT [MaterialActual_MaterialSpec_SegReq_Relation1] FOREIGN KEY ([MaterialSpec_SegReqId], [SegReqId], [WorkRequestId]) REFERENCES [dbo].[MaterialSpec_SegReq] ([MaterialSpec_SegReqId], [SegReqId], [WorkRequestId]) ON DELETE SET NULL,
    CONSTRAINT [MaterialActual_MaterialSublot_Relation1] FOREIGN KEY ([MaterialSublotId]) REFERENCES [dbo].[MaterialSublot] ([MaterialSublotId]),
    CONSTRAINT [MaterialActual_SegmentResponse_Relation1] FOREIGN KEY ([SegmentResponseId]) REFERENCES [dbo].[SegmentResponse] ([SegmentResponseId])
);


GO
CREATE NONCLUSTERED INDEX [IX_MaterialActual_LastModifiedTime]
    ON [dbo].[MaterialActual]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MaterialActual_S95Id]
    ON [dbo].[MaterialActual]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PFM_rUse_EndTime_MaterialLotId_SegmentResponseId]
    ON [dbo].[MaterialActual]([r_Use] ASC, [EndTime] ASC)
    INCLUDE([MaterialLotId], [SegmentResponseId], [MaterialDefinitionId]);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialActual_MaterialClassName]
    ON [dbo].[MaterialActual]([MaterialClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialActual_MaterialDefinitionId]
    ON [dbo].[MaterialActual]([MaterialDefinitionId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialActual_MaterialLotId]
    ON [dbo].[MaterialActual]([MaterialLotId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialActual_MaterialSpec_SegReqId_SegReqId_WorkRequestId]
    ON [dbo].[MaterialActual]([MaterialSpec_SegReqId] ASC, [SegReqId] ASC, [WorkRequestId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialActual_MaterialSublotId]
    ON [dbo].[MaterialActual]([MaterialSublotId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialActual_SegmentResponseId]
    ON [dbo].[MaterialActual]([SegmentResponseId] ASC);

