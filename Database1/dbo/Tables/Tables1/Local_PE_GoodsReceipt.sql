CREATE TABLE [dbo].[Local_PE_GoodsReceipt] (
    [GoodsReceipt_ID]  INT           IDENTITY (1, 1) NOT NULL,
    [ProcessOrder]     VARCHAR (50)  NULL,
    [VendorLot]        VARCHAR (50)  NULL,
    [Material]         VARCHAR (50)  NULL,
    [Batch]            VARCHAR (50)  NULL,
    [Quantity]         FLOAT (53)    NULL,
    [UOM]              VARCHAR (25)  NULL,
    [SAPLocation]      VARCHAR (50)  NULL,
    [TCode]            VARCHAR (50)  NULL,
    [PlantID]          VARCHAR (50)  NULL,
    [PartnerProfile]   VARCHAR (50)  NULL,
    [InsertedDate]     DATETIME      NULL,
    [Timestamp]        DATETIME      NULL,
    [MustArchive]      BIT           NULL,
    [XML]              VARCHAR (MAX) NULL,
    [EventID]          INT           NULL,
    [GRSent]           INT           NULL,
    [JBSent]           INT           NULL,
    [TblIntegrationID] INT           NULL,
    [ProficyLocation]  VARCHAR (50)  NULL,
    CONSTRAINT [PK_Local_PE_GoodsReceipt] PRIMARY KEY CLUSTERED ([GoodsReceipt_ID] ASC)
);

