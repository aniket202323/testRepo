CREATE TABLE [dbo].[StoredAssembly] (
    [Name]                  NVARCHAR (255) NOT NULL,
    [AssemblyType]          NVARCHAR (255) NOT NULL,
    [QualifiedAssemblyName] NVARCHAR (255) NULL,
    [Assembly]              IMAGE          NULL,
    [ModifiedDateTime]      DATETIME       NULL,
    [Version]               BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Name] ASC, [AssemblyType] ASC)
);

