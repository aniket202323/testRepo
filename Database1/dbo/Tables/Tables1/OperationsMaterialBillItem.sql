CREATE TABLE [dbo].[OperationsMaterialBillItem] (
    [Name]                         NVARCHAR (50)    NULL,
    [ParentName]                   NVARCHAR (50)    NULL,
    [S95Id]                        NVARCHAR (50)    NULL,
    [OperationsMaterialBillItemId] UNIQUEIDENTIFIER NOT NULL,
    [Description]                  NVARCHAR (255)   NULL,
    [S95Type]                      NVARCHAR (50)    NULL,
    [LastModifiedTime]             DATETIME         NULL,
    [LastModifiedBy]               NVARCHAR (255)   NULL,
    [Version]                      BIGINT           NULL,
    [OperationsMaterialBillId]     UNIQUEIDENTIFIER NOT NULL,
    [WorkDefinitionId]             UNIQUEIDENTIFIER NOT NULL,
    [MaterialSpec_ProcSegId]       UNIQUEIDENTIFIER NULL,
    [ProcSegId]                    UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([OperationsMaterialBillItemId] ASC, [OperationsMaterialBillId] ASC, [WorkDefinitionId] ASC),
    CONSTRAINT [OperationsMaterialBillItem_MaterialSpec_ProcSeg_Relation1] FOREIGN KEY ([MaterialSpec_ProcSegId], [ProcSegId]) REFERENCES [dbo].[MaterialSpec_ProcSeg] ([MaterialSpec_ProcSegId], [ProcSegId]),
    CONSTRAINT [OperationsMaterialBillItem_OperationsMaterialBill_Relation1] FOREIGN KEY ([OperationsMaterialBillId], [WorkDefinitionId]) REFERENCES [dbo].[OperationsMaterialBill] ([OperationsMaterialBillId], [WorkDefinitionId])
);


GO
CREATE NONCLUSTERED INDEX [IX_OperationsMaterialBillItem_S95Id]
    ON [dbo].[OperationsMaterialBillItem]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_OperationsMaterialBillItem_LastModifiedTime]
    ON [dbo].[OperationsMaterialBillItem]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_OperationsMaterialBillItem_OperationsMaterialBillId_WorkDefinitionId]
    ON [dbo].[OperationsMaterialBillItem]([OperationsMaterialBillId] ASC, [WorkDefinitionId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_OperationsMaterialBillItem_MaterialSpec_ProcSegId_ProcSegId]
    ON [dbo].[OperationsMaterialBillItem]([MaterialSpec_ProcSegId] ASC, [ProcSegId] ASC);

