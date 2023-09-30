CREATE TABLE [dbo].[ServiceProvider] (
    [Id]               UNIQUEIDENTIFIER NOT NULL,
    [Description]      NVARCHAR (255)   NULL,
    [RestAddress]      NVARCHAR (255)   NULL,
    [Version]          BIGINT           NULL,
    [TypeDefinitionId] UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [ServiceProvider_TypeDefinition_Relation1] FOREIGN KEY ([TypeDefinitionId]) REFERENCES [dbo].[TypeDefinition] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ServiceProvider_TypeDefinitionId]
    ON [dbo].[ServiceProvider]([TypeDefinitionId] ASC);

