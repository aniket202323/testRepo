CREATE TABLE [dbo].[VariableDefinition_UserActivityDefinition] (
    [VariableDefinitionId]           NVARCHAR (64)    NOT NULL,
    [DataType]                       INT              NULL,
    [Description]                    NVARCHAR (255)   NULL,
    [DisplayName]                    NVARCHAR (50)    NULL,
    [Version]                        BIGINT           NULL,
    [UserActivityDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [UserActivityDefinitionRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([UserActivityDefinitionId] ASC, [UserActivityDefinitionRevision] ASC, [VariableDefinitionId] ASC),
    CONSTRAINT [VariableDefinition_UserActivityDefinition_UserActivityDefinition_Relation1] FOREIGN KEY ([UserActivityDefinitionId], [UserActivityDefinitionRevision]) REFERENCES [dbo].[UserActivityDefinition] ([UserActivityDefinitionId], [UserActivityDefinitionRevision])
);

