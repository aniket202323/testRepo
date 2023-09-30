CREATE TABLE [dbo].[SpecProp_MaterialSpec_SegReq] (
    [Name]                  NVARCHAR (255)   NOT NULL,
    [Description]           NVARCHAR (255)   NULL,
    [DataType]              INT              NULL,
    [UnitOfMeasure]         NVARCHAR (255)   NULL,
    [TimeStamp]             DATETIME         NULL,
    [Value]                 SQL_VARIANT      NULL,
    [Version]               BIGINT           NULL,
    [MaterialSpec_SegReqId] UNIQUEIDENTIFIER NOT NULL,
    [SegReqId]              UNIQUEIDENTIFIER NOT NULL,
    [WorkRequestId]         UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([MaterialSpec_SegReqId] ASC, [SegReqId] ASC, [WorkRequestId] ASC, [Name] ASC),
    CONSTRAINT [SpecProp_MaterialSpec_SegReq_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [SpecProp_MaterialSpec_SegReq_MaterialSpec_SegReq_Relation1] FOREIGN KEY ([MaterialSpec_SegReqId], [SegReqId], [WorkRequestId]) REFERENCES [dbo].[MaterialSpec_SegReq] ([MaterialSpec_SegReqId], [SegReqId], [WorkRequestId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecProp_MaterialSpec_SegReq_ItemId]
    ON [dbo].[SpecProp_MaterialSpec_SegReq]([ItemId] ASC);

