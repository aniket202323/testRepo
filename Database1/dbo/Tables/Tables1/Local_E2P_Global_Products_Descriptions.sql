CREATE TABLE [dbo].[Local_E2P_Global_Products_Descriptions] (
    [ProductDescriptionId] INT            IDENTITY (1, 1) NOT NULL,
    [ProductId]            INT            NOT NULL,
    [Language]             VARCHAR (25)   NOT NULL,
    [Value]                VARCHAR (5000) NOT NULL,
    CONSTRAINT [LocalE2PGlobalProductsDescriptions_PK_ProductDescriptionId] PRIMARY KEY CLUSTERED ([ProductDescriptionId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_Products_Descriptions_Local_E2P_Global_Products] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Local_E2P_Global_Products] ([ProductId])
);

