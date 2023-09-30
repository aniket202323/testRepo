CREATE TABLE [dbo].[RequestMaterialBillItem] (
    [Name]                      NVARCHAR (50)    NULL,
    [ParentName]                NVARCHAR (50)    NULL,
    [S95Id]                     NVARCHAR (50)    NULL,
    [RequestMaterialBillItemId] UNIQUEIDENTIFIER NOT NULL,
    [Description]               NVARCHAR (255)   NULL,
    [S95Type]                   NVARCHAR (50)    NULL,
    [LastModifiedTime]          DATETIME         NULL,
    [LastModifiedBy]            NVARCHAR (255)   NULL,
    [Version]                   BIGINT           NULL,
    [RequestMaterialBillId]     UNIQUEIDENTIFIER NOT NULL,
    [WorkRequestId]             UNIQUEIDENTIFIER NOT NULL,
    [MaterialSpec_SegReqId]     UNIQUEIDENTIFIER NULL,
    [SegReqId]                  UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([RequestMaterialBillItemId] ASC, [RequestMaterialBillId] ASC, [WorkRequestId] ASC),
    CONSTRAINT [RequestMaterialBillItem_MaterialSpec_SegReq_Relation1] FOREIGN KEY ([MaterialSpec_SegReqId], [SegReqId], [WorkRequestId]) REFERENCES [dbo].[MaterialSpec_SegReq] ([MaterialSpec_SegReqId], [SegReqId], [WorkRequestId]),
    CONSTRAINT [RequestMaterialBillItem_RequestMaterialBill_Relation1] FOREIGN KEY ([RequestMaterialBillId], [WorkRequestId]) REFERENCES [dbo].[RequestMaterialBill] ([RequestMaterialBillId], [WorkRequestId])
);


GO
ALTER TABLE [dbo].[RequestMaterialBillItem] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_RequestMaterialBillItem_S95Id]
    ON [dbo].[RequestMaterialBillItem]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_RequestMaterialBillItem_LastModifiedTime]
    ON [dbo].[RequestMaterialBillItem]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_RequestMaterialBillItem_RequestMaterialBillId_WorkRequestId]
    ON [dbo].[RequestMaterialBillItem]([RequestMaterialBillId] ASC, [WorkRequestId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_RequestMaterialBillItem_MaterialSpec_SegReqId_SegReqId_WorkRequestId]
    ON [dbo].[RequestMaterialBillItem]([MaterialSpec_SegReqId] ASC, [SegReqId] ASC, [WorkRequestId] ASC);

