CREATE TABLE [dbo].[Local_E2P_Global_WeightDimensions_PackingUnits] (
    [PackingUnitId]            INT           IDENTITY (1, 1) NOT NULL,
    [ComponentId]              INT           NOT NULL,
    [Name]                     VARCHAR (255) NOT NULL,
    [Gtin]                     VARCHAR (255) NULL,
    [BaseUnitQuantity]         VARCHAR (255) NULL,
    [AlternativeUnitOfMeasure] VARCHAR (255) NULL,
    [UnitOfMeasureSystem]      VARCHAR (255) NULL,
    [ConsumerUnitsPerUnit]     VARCHAR (25)  NULL,
    [NetWeight]                VARCHAR (25)  NULL,
    [NetWeightUnitOfMeasure]   VARCHAR (255) NULL,
    [GrossWeight]              VARCHAR (25)  NULL,
    [GrossWithPallet]          VARCHAR (25)  NULL,
    [GrossWithoutPallet]       VARCHAR (25)  NULL,
    [GrossWeightUnitOfMeasure] VARCHAR (255) NULL,
    [Depth]                    VARCHAR (25)  NULL,
    [Width]                    VARCHAR (25)  NULL,
    [Height]                   VARCHAR (25)  NULL,
    [DimensionUnitOfMeasure]   VARCHAR (255) NULL,
    CONSTRAINT [LocalE2PGlobalWeightDimensionsPackingUnits_PK_PackingUnitId] PRIMARY KEY CLUSTERED ([PackingUnitId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_WeightDimensions_PackingUnits_Local_E2P_Global_Components] FOREIGN KEY ([ComponentId]) REFERENCES [dbo].[Local_E2P_Global_Components] ([ComponentId])
);

