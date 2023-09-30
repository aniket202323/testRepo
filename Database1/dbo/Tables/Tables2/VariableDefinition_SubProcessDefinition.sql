CREATE TABLE [dbo].[VariableDefinition_SubProcessDefinition] (
    [VariableDefinitionId]         NVARCHAR (64)    NOT NULL,
    [DataType]                     INT              NULL,
    [Description]                  NVARCHAR (255)   NULL,
    [DisplayName]                  NVARCHAR (50)    NULL,
    [Version]                      BIGINT           NULL,
    [SubProcessDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [SubProcessDefinitionRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([SubProcessDefinitionId] ASC, [SubProcessDefinitionRevision] ASC, [VariableDefinitionId] ASC),
    CONSTRAINT [VariableDefinition_SubProcessDefinition_SubProcessDefinition_Relation1] FOREIGN KEY ([SubProcessDefinitionId], [SubProcessDefinitionRevision]) REFERENCES [dbo].[SubProcessDefinition] ([SubProcessDefinitionId], [SubProcessDefinitionRevision])
);


GO
ALTER TABLE [dbo].[VariableDefinition_SubProcessDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);

