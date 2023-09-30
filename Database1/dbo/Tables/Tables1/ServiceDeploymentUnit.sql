CREATE TABLE [dbo].[ServiceDeploymentUnit] (
    [Version]            BIGINT NULL,
    [ServiceNamespaceId] INT    NOT NULL,
    [ServiceContainerId] INT    NOT NULL,
    PRIMARY KEY CLUSTERED ([ServiceNamespaceId] ASC, [ServiceContainerId] ASC),
    CONSTRAINT [ServiceDeploymentUnit_ServiceContainer_Relation1] FOREIGN KEY ([ServiceContainerId]) REFERENCES [dbo].[ServiceContainer] ([Id]),
    CONSTRAINT [ServiceDeploymentUnit_ServiceNamespace_Relation1] FOREIGN KEY ([ServiceNamespaceId]) REFERENCES [dbo].[ServiceNamespace] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_ServiceDeploymentUnit_ServiceContainerId]
    ON [dbo].[ServiceDeploymentUnit]([ServiceContainerId] ASC);

