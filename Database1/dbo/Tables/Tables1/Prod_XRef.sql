CREATE TABLE [dbo].[Prod_XRef] (
    [Prod_Code_XRef] [dbo].[Varchar_XRef] NOT NULL,
    [Prod_Id]        INT                  NULL,
    [PU_Id]          INT                  NULL,
    CONSTRAINT [Prod_XRef_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [Prod_XRef_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [Prod_XRef_UC_PUIdProdId] UNIQUE NONCLUSTERED ([PU_Id] ASC, [Prod_Id] ASC)
);

