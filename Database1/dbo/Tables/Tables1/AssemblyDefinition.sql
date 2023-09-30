CREATE TABLE [dbo].[AssemblyDefinition] (
    [Id]       UNIQUEIDENTIFIER NOT NULL,
    [FullName] NVARCHAR (255)   NULL,
    [Version]  BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_AssemblyDefinition_FullName]
    ON [dbo].[AssemblyDefinition]([FullName] ASC);

