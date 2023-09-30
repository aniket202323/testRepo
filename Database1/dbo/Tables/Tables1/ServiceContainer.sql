CREATE TABLE [dbo].[ServiceContainer] (
    [Id]                   INT            IDENTITY (1, 1) NOT NULL,
    [ContainerName]        NVARCHAR (255) NULL,
    [Description]          NVARCHAR (255) NULL,
    [DeployToAllInstances] BIT            NULL,
    [r_Order]              INT            NULL,
    [IsEssential]          BIT            NULL,
    [Version]              BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ServiceContainer_ContainerName]
    ON [dbo].[ServiceContainer]([ContainerName] ASC);

