CREATE TABLE [dbo].[ServiceDeployment] (
    [Version]            BIGINT NULL,
    [ServerId]           INT    NOT NULL,
    [ServiceNamespaceId] INT    NOT NULL,
    [ServiceContainerId] INT    NOT NULL,
    PRIMARY KEY CLUSTERED ([ServerId] ASC, [ServiceNamespaceId] ASC, [ServiceContainerId] ASC),
    CONSTRAINT [ServiceDeployment_ServerInstance_Relation1] FOREIGN KEY ([ServerId]) REFERENCES [dbo].[ServerInstance] ([Id]),
    CONSTRAINT [ServiceDeployment_ServiceDeploymentUnit_Relation1] FOREIGN KEY ([ServiceNamespaceId], [ServiceContainerId]) REFERENCES [dbo].[ServiceDeploymentUnit] ([ServiceNamespaceId], [ServiceContainerId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ServiceDeployment_ServiceNamespaceId_ServiceContainerId]
    ON [dbo].[ServiceDeployment]([ServiceNamespaceId] ASC, [ServiceContainerId] ASC);

