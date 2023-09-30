CREATE TABLE [dbo].[Local_E2P_Global_WeightDimensions_TransportPallets] (
    [TransportPalletId]                 INT           IDENTITY (1, 1) NOT NULL,
    [PackingUnitId]                     INT           NOT NULL,
    [TruckPalletStackHeightMaximum]     VARCHAR (25)  NULL,
    [WarehousePalletStackHeightMaximum] VARCHAR (25)  NULL,
    [WarehouseCaseStackHeightMaximum]   VARCHAR (25)  NULL,
    [StackingPatternCode]               VARCHAR (25)  NULL,
    [CubeEfficiency]                    VARCHAR (25)  NULL,
    [CustomerUnitsPerLayer]             VARCHAR (25)  NULL,
    [NumberOfLayers]                    VARCHAR (25)  NULL,
    [NumberOfCustomerUnits]             VARCHAR (25)  NULL,
    [TransportVolume]                   VARCHAR (25)  NULL,
    [TransportVolumeUnitOfMeasure]      VARCHAR (255) NULL,
    [StackingPatternUniqueId]           VARCHAR (255) NULL,
    CONSTRAINT [LocalE2PGlobalWeightDimensionsTransportPallets_PK_TransportPalletId] PRIMARY KEY CLUSTERED ([TransportPalletId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_WeightDimensions_TransportPallets_Local_E2P_Global_WeightDimensions_PackingUnits] FOREIGN KEY ([PackingUnitId]) REFERENCES [dbo].[Local_E2P_Global_WeightDimensions_PackingUnits] ([PackingUnitId])
);

