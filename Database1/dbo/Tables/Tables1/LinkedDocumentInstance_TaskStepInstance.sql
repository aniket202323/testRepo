CREATE TABLE [dbo].[LinkedDocumentInstance_TaskStepInstance] (
    [InstanceId]          UNIQUEIDENTIFIER NOT NULL,
    [DocumentId]          UNIQUEIDENTIFIER NOT NULL,
    [DocumentName]        NVARCHAR (50)    NULL,
    [DocumentDisplayName] NVARCHAR (255)   NULL,
    [DocumentIsVisibile]  BIT              NULL,
    [DocumentUrlUnc]      NVARCHAR (255)   NULL,
    [Version]             BIGINT           NULL,
    [BaseId]              UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([BaseId] ASC, [InstanceId] ASC, [DocumentId] ASC),
    CONSTRAINT [LinkedDocumentInstance_TaskStepInstance_TaskStepInstance_Relation1] FOREIGN KEY ([BaseId]) REFERENCES [dbo].[TaskStepInstance] ([Id])
);

