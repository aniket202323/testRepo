CREATE TABLE [dbo].[Trans_Products] (
    [Is_Delete]           TINYINT NULL,
    [Prod_Id]             INT     NOT NULL,
    [PU_Id]               INT     NOT NULL,
    [Trans_Id]            INT     NOT NULL,
    [Validation_Trans_Id] INT     NULL,
    CONSTRAINT [Trans_Prod_PK_TransProdPU] PRIMARY KEY CLUSTERED ([Trans_Id] ASC, [Prod_Id] ASC, [PU_Id] ASC),
    CONSTRAINT [Trans_Products_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [Trans_Products_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [Trans_Products_FK_TransId] FOREIGN KEY ([Trans_Id]) REFERENCES [dbo].[Transactions] ([Trans_Id])
);

