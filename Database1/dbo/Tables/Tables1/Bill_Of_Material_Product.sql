CREATE TABLE [dbo].[Bill_Of_Material_Product] (
    [BOM_Product_Id]     INT    IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [BOM_Formulation_Id] BIGINT NOT NULL,
    [Prod_Id]            INT    NOT NULL,
    [PU_Id]              INT    NULL,
    CONSTRAINT [BOMProduct_PK_BOMProductId] PRIMARY KEY NONCLUSTERED ([BOM_Product_Id] ASC),
    CONSTRAINT [BOMProduct_FK_BOMFormulationId] FOREIGN KEY ([BOM_Formulation_Id]) REFERENCES [dbo].[Bill_Of_Material_Formulation] ([BOM_Formulation_Id]),
    CONSTRAINT [BOMProduct_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [BOMProduct_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [BOMProduct_UC_ProdIdFormulationId] UNIQUE NONCLUSTERED ([Prod_Id] ASC, [BOM_Formulation_Id] ASC, [PU_Id] ASC)
);

