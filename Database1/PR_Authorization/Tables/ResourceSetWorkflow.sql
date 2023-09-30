CREATE TABLE [PR_Authorization].[ResourceSetWorkflow] (
    [ResourceSetId]    UNIQUEIDENTIFIER NOT NULL,
    [WorkflowId]       UNIQUEIDENTIFIER NOT NULL,
    [Version]          BIGINT           NOT NULL,
    [CreatedBy]        NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]      DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]   NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate] DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_ResourceSetWorkflow] PRIMARY KEY CLUSTERED ([ResourceSetId] ASC, [WorkflowId] ASC),
    CONSTRAINT [FK_ResourceSetWorkflow_ResourceSet] FOREIGN KEY ([ResourceSetId]) REFERENCES [PR_Authorization].[ResourceSet] ([ResourceSetId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_ResourceGroupWorkflow]
    ON [PR_Authorization].[ResourceSetWorkflow]([WorkflowId] ASC, [ResourceSetId] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This is designed to be able to add security on Workflows... Currently do not know enough to determine what that really means. But I think that means the InstanceId in the WorkflowInstance table.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'ResourceSetWorkflow';

