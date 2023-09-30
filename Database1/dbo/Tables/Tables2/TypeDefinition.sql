CREATE TABLE [dbo].[TypeDefinition] (
    [Id]           UNIQUEIDENTIFIER NOT NULL,
    [TypeFullName] NVARCHAR (255)   NULL,
    [Version]      BIGINT           NULL,
    [AssemblyId]   UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [TypeDefinition_AssemblyDefinition_Relation1] FOREIGN KEY ([AssemblyId]) REFERENCES [dbo].[AssemblyDefinition] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TypeDefinition_TypeFullName_AssemblyId]
    ON [dbo].[TypeDefinition]([TypeFullName] ASC, [AssemblyId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_TypeDefinition_AssemblyId]
    ON [dbo].[TypeDefinition]([AssemblyId] ASC);

