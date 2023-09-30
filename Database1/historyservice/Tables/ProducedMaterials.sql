CREATE TABLE [historyservice].[ProducedMaterials] (
    [Id]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description] NVARCHAR (255) NULL,
    [MaterialId]  BIGINT         NULL,
    [Name]        NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [U_PRDCRLS_MATERIALID] UNIQUE NONCLUSTERED ([MaterialId] ASC)
);

