CREATE TABLE [dbo].[ExpressionVariableDefinition] (
    [ExpressionVariableDefinitionPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [Name]                                   NVARCHAR (255)   NULL,
    [Description]                            NVARCHAR (255)   NULL,
    [ValidationPattern]                      NVARCHAR (255)   NULL,
    [DataType]                               INT              NULL,
    [Version]                                BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([ExpressionVariableDefinitionPropertyId] ASC)
);

