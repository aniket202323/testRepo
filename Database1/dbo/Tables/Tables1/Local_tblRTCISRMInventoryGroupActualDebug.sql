CREATE TABLE [dbo].[Local_tblRTCISRMInventoryGroupActualDebug] (
    [Id]                         INT          IDENTITY (1, 1) NOT NULL,
    [BOMRMProdGroupId]           INT          NULL,
    [BOMRMProdGroupDesc]         VARCHAR (50) NULL,
    [ProductGroupCapacity]       INT          NULL,
    [ProductGroupThreshold]      INT          NULL,
    [ActualPalletCntStaging]     INT          NULL,
    [ActualPalletCntPreStaging]  INT          NULL,
    [ActualPalletCntOpenRequest] INT          NULL,
    [ActualPalletCntTot]         INT          NULL,
    [FlgThresholdGTActual]       INT          NULL,
    [FlgNeededForActiveEq0]      INT          NULL,
    [FlgOrderForActive]          INT          NULL,
    [FlgOrderForNext]            INT          NULL,
    [EntryOn]                    DATETIME     NULL
);

