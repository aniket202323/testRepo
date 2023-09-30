CREATE TABLE [dbo].[ComponentModule] (
    [ModuleName]       NVARCHAR (255) NOT NULL,
    [ModuleExecutable] IMAGE          NULL,
    [DependencyNames]  IMAGE          NULL,
    [LastModified]     DATETIME       NULL,
    [Version]          BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([ModuleName] ASC)
);

