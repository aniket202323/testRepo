CREATE TABLE [dbo].[EquipmentSpec_SegReq] (
    [S95Id]                  NVARCHAR (50)    NULL,
    [QuantityUnitOfMeasure]  NVARCHAR (50)    NULL,
    [Quantity]               FLOAT (53)       NULL,
    [EquipmentSpec_SegReqId] UNIQUEIDENTIFIER NOT NULL,
    [Description]            NVARCHAR (255)   NULL,
    [S95Type]                NVARCHAR (50)    NULL,
    [LastModifiedTime]       DATETIME         NULL,
    [LastModifiedBy]         NVARCHAR (255)   NULL,
    [Version]                BIGINT           NULL,
    [SegReqId]               UNIQUEIDENTIFIER NOT NULL,
    [WorkRequestId]          UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([EquipmentSpec_SegReqId] ASC, [SegReqId] ASC, [WorkRequestId] ASC),
    CONSTRAINT [EquipmentSpec_SegReq_SegReq_Relation1] FOREIGN KEY ([SegReqId], [WorkRequestId]) REFERENCES [dbo].[SegReq] ([SegReqId], [WorkRequestId])
);


GO
ALTER TABLE [dbo].[EquipmentSpec_SegReq] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_EquipmentSpec_SegReq_S95Id]
    ON [dbo].[EquipmentSpec_SegReq]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EquipmentSpec_SegReq_LastModifiedTime]
    ON [dbo].[EquipmentSpec_SegReq]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_EquipmentSpec_SegReq_SegReqId_WorkRequestId]
    ON [dbo].[EquipmentSpec_SegReq]([SegReqId] ASC, [WorkRequestId] ASC);

