CREATE TABLE [dbo].[ProductOptionServices] (
    [Version]           BIGINT           NULL,
    [ProductOptionId]   UNIQUEIDENTIFIER NOT NULL,
    [ServiceProviderId] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ProductOptionId] ASC, [ServiceProviderId] ASC),
    CONSTRAINT [ProductOptionServices_ProductOption_Relation1] FOREIGN KEY ([ProductOptionId]) REFERENCES [dbo].[ProductOption] ([Id]),
    CONSTRAINT [ProductOptionServices_ServiceProvider_Relation1] FOREIGN KEY ([ServiceProviderId]) REFERENCES [dbo].[ServiceProvider] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_ProductOptionServices_ServiceProviderId]
    ON [dbo].[ProductOptionServices]([ServiceProviderId] ASC);

