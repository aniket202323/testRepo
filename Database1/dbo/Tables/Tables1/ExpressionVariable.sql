CREATE TABLE [dbo].[ExpressionVariable] (
    [TriggerProperty]                        NVARCHAR (255)   NULL,
    [r_Order]                                INT              NULL,
    [Value]                                  SQL_VARIANT      NULL,
    [Quality]                                SMALLINT         NULL,
    [TimeStamp]                              DATETIME         NULL,
    [Version]                                BIGINT           NULL,
    [ConditionEventDefinitionId]             UNIQUEIDENTIFIER NOT NULL,
    [ExpressionVariableDefinitionPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                                 UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ConditionEventDefinitionId] ASC, [ExpressionVariableDefinitionPropertyId] ASC),
    CONSTRAINT [ExpressionVariable_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [ExpressionVariable_ConditionEventDefinition_Relation1] FOREIGN KEY ([ConditionEventDefinitionId]) REFERENCES [dbo].[ConditionEventDefinition] ([ConditionEventDefinitionId]),
    CONSTRAINT [ExpressionVariable_ExpressionVariableDefinition_Relation1] FOREIGN KEY ([ExpressionVariableDefinitionPropertyId]) REFERENCES [dbo].[ExpressionVariableDefinition] ([ExpressionVariableDefinitionPropertyId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ExpressionVariable_ExpressionVariableDefinitionPropertyId]
    ON [dbo].[ExpressionVariable]([ExpressionVariableDefinitionPropertyId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_ExpressionVariable_ItemId]
    ON [dbo].[ExpressionVariable]([ItemId] ASC);

