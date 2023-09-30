CREATE TABLE [dbo].[OperationsMaterialBill] (
    [Name]                     NVARCHAR (50)    NULL,
    [S95Id]                    NVARCHAR (50)    NULL,
    [OperationsMaterialBillId] UNIQUEIDENTIFIER NOT NULL,
    [Description]              NVARCHAR (255)   NULL,
    [S95Type]                  NVARCHAR (50)    NULL,
    [LastModifiedTime]         DATETIME         NULL,
    [LastModifiedBy]           NVARCHAR (255)   NULL,
    [Version]                  BIGINT           NULL,
    [WorkDefinitionId]         UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([OperationsMaterialBillId] ASC, [WorkDefinitionId] ASC),
    CONSTRAINT [OperationsMaterialBill_WorkDefinition_Relation1] FOREIGN KEY ([WorkDefinitionId]) REFERENCES [dbo].[WorkDefinition] ([WorkDefinitionId])
);


GO
CREATE NONCLUSTERED INDEX [IX_OperationsMaterialBill_S95Id]
    ON [dbo].[OperationsMaterialBill]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_OperationsMaterialBill_LastModifiedTime]
    ON [dbo].[OperationsMaterialBill]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_OperationsMaterialBill_WorkDefinitionId]
    ON [dbo].[OperationsMaterialBill]([WorkDefinitionId] ASC);

