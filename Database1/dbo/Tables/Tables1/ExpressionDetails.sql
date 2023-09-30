CREATE TABLE [dbo].[ExpressionDetails] (
    [ExpressionId]               UNIQUEIDENTIFIER NOT NULL,
    [Name]                       NVARCHAR (255)   NULL,
    [Description]                NVARCHAR (1024)  NULL,
    [ExpressionString]           NVARCHAR (1024)  NULL,
    [Latched]                    BIT              NULL,
    [Version]                    BIGINT           NULL,
    [ConditionEventDefinitionId] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ExpressionId] ASC, [ConditionEventDefinitionId] ASC),
    CONSTRAINT [ExpressionDetails_ConditionEventDefinition_Relation1] FOREIGN KEY ([ConditionEventDefinitionId]) REFERENCES [dbo].[ConditionEventDefinition] ([ConditionEventDefinitionId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ExpressionDetails_ConditionEventDefinitionId]
    ON [dbo].[ExpressionDetails]([ConditionEventDefinitionId] ASC);

