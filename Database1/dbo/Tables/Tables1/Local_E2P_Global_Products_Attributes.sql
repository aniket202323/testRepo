CREATE TABLE [dbo].[Local_E2P_Global_Products_Attributes] (
    [ProductAttributeId] INT           IDENTITY (1, 1) NOT NULL,
    [ProductId]          INT           NOT NULL,
    [Type]               VARCHAR (255) NOT NULL,
    [TypeDescription]    VARCHAR (255) NOT NULL,
    [ValueId]            VARCHAR (255) NULL,
    [ValueDescription]   VARCHAR (255) NULL,
    CONSTRAINT [LocalE2PGlobalProductsAttributes_PK_ProductAttributeId] PRIMARY KEY CLUSTERED ([ProductAttributeId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_Products_Attributes_Local_E2P_Global_Products] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Local_E2P_Global_Products] ([ProductId])
);

