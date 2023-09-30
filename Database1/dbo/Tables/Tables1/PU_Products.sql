CREATE TABLE [dbo].[PU_Products] (
    [Prod_Id] INT NOT NULL,
    [PU_Id]   INT NOT NULL,
    CONSTRAINT [PU_Products_PK_ProdIdPUId] PRIMARY KEY CLUSTERED ([Prod_Id] ASC, [PU_Id] ASC),
    CONSTRAINT [PU_Products_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [PU_Products_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);


GO
CREATE NONCLUSTERED INDEX [PU_Products_By_Pu]
    ON [dbo].[PU_Products]([PU_Id] ASC);

