CREATE TABLE [dbo].[ProductApplicationData] (
    [ProductApplicationId]          UNIQUEIDENTIFIER NOT NULL,
    [ProductApplicationName]        NVARCHAR (255)   NULL,
    [ProductServerMachineName]      NVARCHAR (255)   NULL,
    [ProductApplicationDescription] NVARCHAR (255)   NULL,
    [Version]                       BIGINT           NULL,
    [ProductID]                     NVARCHAR (255)   NULL,
    PRIMARY KEY CLUSTERED ([ProductApplicationId] ASC),
    CONSTRAINT [ProductApplicationData_ProficyProduct_Relation1] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[ProficyProduct] ([ProductID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProductApplicationData_ProductApplicationName_ProductID]
    ON [dbo].[ProductApplicationData]([ProductApplicationName] ASC, [ProductID] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_ProductApplicationData_ProductID]
    ON [dbo].[ProductApplicationData]([ProductID] ASC);

