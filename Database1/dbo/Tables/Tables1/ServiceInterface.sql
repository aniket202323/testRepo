CREATE TABLE [dbo].[ServiceInterface] (
    [Name]              NVARCHAR (255)   NULL,
    [LogicalName]       NVARCHAR (255)   NULL,
    [Description]       NVARCHAR (255)   NULL,
    [Version]           BIGINT           NULL,
    [ServiceProviderId] UNIQUEIDENTIFIER NOT NULL,
    [TypeDefinitionId]  UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ServiceProviderId] ASC, [TypeDefinitionId] ASC),
    CONSTRAINT [ServiceInterface_ServiceProvider_Relation1] FOREIGN KEY ([ServiceProviderId]) REFERENCES [dbo].[ServiceProvider] ([Id]),
    CONSTRAINT [ServiceInterface_TypeDefinition_Relation1] FOREIGN KEY ([TypeDefinitionId]) REFERENCES [dbo].[TypeDefinition] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_ServiceInterface_TypeDefinitionId]
    ON [dbo].[ServiceInterface]([TypeDefinitionId] ASC);

