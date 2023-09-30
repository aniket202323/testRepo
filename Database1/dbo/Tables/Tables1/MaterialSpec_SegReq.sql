CREATE TABLE [dbo].[MaterialSpec_SegReq] (
    [r_Use]                 NVARCHAR (255)   NULL,
    [S95Id]                 NVARCHAR (50)    NULL,
    [QuantityUnitOfMeasure] NVARCHAR (50)    NULL,
    [Quantity]              FLOAT (53)       NULL,
    [MaterialSpec_SegReqId] UNIQUEIDENTIFIER NOT NULL,
    [Description]           NVARCHAR (255)   NULL,
    [S95Type]               NVARCHAR (50)    NULL,
    [LastModifiedTime]      DATETIME         NULL,
    [LastModifiedBy]        NVARCHAR (255)   NULL,
    [Version]               BIGINT           NULL,
    [SegReqId]              UNIQUEIDENTIFIER NOT NULL,
    [WorkRequestId]         UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([MaterialSpec_SegReqId] ASC, [SegReqId] ASC, [WorkRequestId] ASC),
    CONSTRAINT [MaterialSpec_SegReq_SegReq_Relation1] FOREIGN KEY ([SegReqId], [WorkRequestId]) REFERENCES [dbo].[SegReq] ([SegReqId], [WorkRequestId])
);


GO
ALTER TABLE [dbo].[MaterialSpec_SegReq] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_MaterialSpec_SegReq_S95Id]
    ON [dbo].[MaterialSpec_SegReq]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MaterialSpec_SegReq_LastModifiedTime]
    ON [dbo].[MaterialSpec_SegReq]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialSpec_SegReq_SegReqId_WorkRequestId]
    ON [dbo].[MaterialSpec_SegReq]([SegReqId] ASC, [WorkRequestId] ASC);

