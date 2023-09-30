CREATE TABLE [dbo].[RequestMaterialBill] (
    [Name]                  NVARCHAR (50)    NULL,
    [S95Id]                 NVARCHAR (50)    NULL,
    [RequestMaterialBillId] UNIQUEIDENTIFIER NOT NULL,
    [Description]           NVARCHAR (255)   NULL,
    [S95Type]               NVARCHAR (50)    NULL,
    [LastModifiedTime]      DATETIME         NULL,
    [LastModifiedBy]        NVARCHAR (255)   NULL,
    [Version]               BIGINT           NULL,
    [WorkRequestId]         UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([RequestMaterialBillId] ASC, [WorkRequestId] ASC),
    CONSTRAINT [RequestMaterialBill_WorkRequest_Relation1] FOREIGN KEY ([WorkRequestId]) REFERENCES [dbo].[WorkRequest] ([WorkRequestId])
);


GO
ALTER TABLE [dbo].[RequestMaterialBill] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_RequestMaterialBill_S95Id]
    ON [dbo].[RequestMaterialBill]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_RequestMaterialBill_LastModifiedTime]
    ON [dbo].[RequestMaterialBill]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_RequestMaterialBill_WorkRequestId]
    ON [dbo].[RequestMaterialBill]([WorkRequestId] ASC);

