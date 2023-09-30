CREATE TABLE [dbo].[ComponentModuleDependency] (
    [DependencyName] NVARCHAR (255) NOT NULL,
    [DependencyBits] IMAGE          NULL,
    [IsZipped]       BIT            NULL,
    [LastModified]   DATETIME       NULL,
    [Version]        BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([DependencyName] ASC)
);

