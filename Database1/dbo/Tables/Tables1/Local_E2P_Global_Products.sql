CREATE TABLE [dbo].[Local_E2P_Global_Products] (
    [ProductId]                      INT           IDENTITY (1, 1) NOT NULL,
    [ComponentId]                    INT           NOT NULL,
    [ProductCode]                    VARCHAR (25)  NOT NULL,
    [MaterialType]                   VARCHAR (25)  NOT NULL,
    [BaseUnitOfMeasure]              VARCHAR (255) NOT NULL,
    [NetWeightMetric]                VARCHAR (25)  NULL,
    [NetWeightMetricUnitOfMeasure]   VARCHAR (255) NULL,
    [NetWeightImperial]              VARCHAR (25)  NULL,
    [NetWeightImperialUnitOfMeasure] VARCHAR (255) NULL,
    [TransportationGroup]            VARCHAR (255) NULL,
    [AuthorizationGroup]             VARCHAR (255) NULL,
    [GeneralItemCategoryGroup]       VARCHAR (255) NULL,
    [StatisticalUnit]                VARCHAR (25)  NULL,
    CONSTRAINT [LocalE2PGlobalProducts_PK_ProductId] PRIMARY KEY CLUSTERED ([ProductId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_Products_Local_E2P_Global_Components] FOREIGN KEY ([ComponentId]) REFERENCES [dbo].[Local_E2P_Global_Components] ([ComponentId])
);

