CREATE TABLE [dbo].[ConditionEventDefinition] (
    [SingleOn]                   INT              NULL,
    [TriggerOn]                  INT              NULL,
    [ConditionEventDefinitionId] UNIQUEIDENTIFIER NOT NULL,
    [Name]                       NVARCHAR (255)   NULL,
    [Description]                NVARCHAR (1024)  NULL,
    [Enabled]                    BIT              NULL,
    [Version]                    BIGINT           NULL,
    [ItemId]                     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ConditionEventDefinitionId] ASC),
    CONSTRAINT [ConditionEventDefinition_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ConditionEventDefinition_Name]
    ON [dbo].[ConditionEventDefinition]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_ConditionEventDefinition_ItemId]
    ON [dbo].[ConditionEventDefinition]([ItemId] ASC);

