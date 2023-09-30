CREATE TABLE [dbo].[EquipmentActual] (
    [S95Id]                  NVARCHAR (50)    NULL,
    [QuantityUnitOfMeasure]  NVARCHAR (50)    NULL,
    [Quantity]               FLOAT (53)       NULL,
    [r_Use]                  NVARCHAR (255)   NULL,
    [StartTime]              DATETIME         NULL,
    [EndTime]                DATETIME         NULL,
    [EquipmentActualId]      UNIQUEIDENTIFIER NOT NULL,
    [Description]            NVARCHAR (255)   NULL,
    [S95Type]                NVARCHAR (50)    NULL,
    [LastModifiedTime]       DATETIME         NULL,
    [LastModifiedBy]         NVARCHAR (255)   NULL,
    [Version]                BIGINT           NULL,
    [EquipmentId]            UNIQUEIDENTIFIER NULL,
    [EquipmentClassName]     NVARCHAR (200)   NULL,
    [SegmentResponseId]      UNIQUEIDENTIFIER NULL,
    [EquipmentSpec_SegReqId] UNIQUEIDENTIFIER NULL,
    [SegReqId]               UNIQUEIDENTIFIER NULL,
    [WorkRequestId]          UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([EquipmentActualId] ASC),
    CONSTRAINT [EquipmentActual_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]),
    CONSTRAINT [EquipmentActual_EquipmentClass_Relation1] FOREIGN KEY ([EquipmentClassName]) REFERENCES [dbo].[EquipmentClass] ([EquipmentClassName]),
    CONSTRAINT [EquipmentActual_EquipmentSpec_SegReq_Relation1] FOREIGN KEY ([EquipmentSpec_SegReqId], [SegReqId], [WorkRequestId]) REFERENCES [dbo].[EquipmentSpec_SegReq] ([EquipmentSpec_SegReqId], [SegReqId], [WorkRequestId]) ON DELETE SET NULL,
    CONSTRAINT [EquipmentActual_SegmentResponse_Relation1] FOREIGN KEY ([SegmentResponseId]) REFERENCES [dbo].[SegmentResponse] ([SegmentResponseId])
);


GO
CREATE NONCLUSTERED INDEX [IX_EquipmentActual_LastModifiedTime]
    ON [dbo].[EquipmentActual]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EquipmentActual_S95Id]
    ON [dbo].[EquipmentActual]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PFM_rUse_EndTime_EquipmentId_SegmentResponseId]
    ON [dbo].[EquipmentActual]([r_Use] ASC, [EndTime] ASC, [EquipmentId] ASC)
    INCLUDE([SegmentResponseId]);


GO
CREATE NONCLUSTERED INDEX [NC_EquipmentActual_EquipmentClassName]
    ON [dbo].[EquipmentActual]([EquipmentClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_EquipmentActual_EquipmentId]
    ON [dbo].[EquipmentActual]([EquipmentId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_EquipmentActual_EquipmentSpec_SegReqId_SegReqId_WorkRequestId]
    ON [dbo].[EquipmentActual]([EquipmentSpec_SegReqId] ASC, [SegReqId] ASC, [WorkRequestId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_EquipmentActual_SegmentResponseId]
    ON [dbo].[EquipmentActual]([SegmentResponseId] ASC);

