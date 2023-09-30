CREATE TABLE [dbo].[Bill_Of_Material_Substitution] (
    [BOM_Substitution_Id]     BIGINT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [BOM_Formulation_Item_Id] BIGINT     NOT NULL,
    [BOM_Substitution_Order]  INT        NOT NULL,
    [Conversion_Factor]       FLOAT (53) CONSTRAINT [BOMSubstitution_DF_ConversionFactor] DEFAULT ((1)) NOT NULL,
    [Eng_Unit_Id]             INT        NOT NULL,
    [Prod_Id]                 INT        NOT NULL,
    CONSTRAINT [BOMSubstitution_PK_SubstitutionID] PRIMARY KEY NONCLUSTERED ([BOM_Substitution_Id] ASC),
    CONSTRAINT [BOMSubstitution_FK_BOMFormulationItemId] FOREIGN KEY ([BOM_Formulation_Item_Id]) REFERENCES [dbo].[Bill_Of_Material_Formulation_Item] ([BOM_Formulation_Item_Id]),
    CONSTRAINT [BOMSubstitution_FK_EUId] FOREIGN KEY ([Eng_Unit_Id]) REFERENCES [dbo].[Engineering_Unit] ([Eng_Unit_Id]),
    CONSTRAINT [BOMSubstitution_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [BOMSubstitution_UC_FormulationItemIdProdId] UNIQUE NONCLUSTERED ([BOM_Formulation_Item_Id] ASC, [Prod_Id] ASC)
);

