CREATE TABLE [dbo].[WorkflowPendingImport] (
    [Id]      UNIQUEIDENTIFIER NOT NULL,
    [DataSet] IMAGE            NULL,
    [Version] BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

