CREATE TABLE [dbo].[ProficyProduct] (
    [ProductID]          NVARCHAR (255) NOT NULL,
    [ProductDisplayName] NVARCHAR (255) NULL,
    [SingleLogOnEnabled] BIT            NULL,
    [Version]            BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([ProductID] ASC)
);

