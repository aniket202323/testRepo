CREATE TABLE [dbo].[Bill_Of_Material_Formulation_Item] (
    [BOM_Formulation_Item_Id] BIGINT       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Alias]                   VARCHAR (50) NULL,
    [BOM_Formulation_Id]      BIGINT       NOT NULL,
    [BOM_Formulation_Order]   INT          NOT NULL,
    [Comment_Id]              INT          NULL,
    [Eng_Unit_Id]             INT          NOT NULL,
    [Location_Id]             INT          NULL,
    [Lot_Desc]                VARCHAR (50) NULL,
    [Lower_Tolerance]         FLOAT (53)   NULL,
    [LTolerance_Precision]    INT          CONSTRAINT [BOMFormulationItem_DF_LTolerancePrecision] DEFAULT ((2)) NOT NULL,
    [Prod_Id]                 INT          NOT NULL,
    [PU_Id]                   INT          NULL,
    [Quantity]                FLOAT (53)   NOT NULL,
    [Quantity_Precision]      INT          CONSTRAINT [BOMFormulationItem_DF_QuantityPrecision] DEFAULT ((2)) NOT NULL,
    [Scrap_Factor]            FLOAT (53)   NOT NULL,
    [Upper_Tolerance]         FLOAT (53)   NULL,
    [Use_Event_Components]    BIT          CONSTRAINT [BOMFormulationItem_DF_UseEventComponents] DEFAULT ((1)) NOT NULL,
    [UTolerance_Precision]    INT          CONSTRAINT [BOMFormulationItem_DF_UTolerancePrecision] DEFAULT ((2)) NOT NULL,
    CONSTRAINT [BOMFormulationItem_PK_FormulationItemId] PRIMARY KEY NONCLUSTERED ([BOM_Formulation_Item_Id] ASC),
    CONSTRAINT [BOMFormulationItem_FK_BOMFormulationId] FOREIGN KEY ([BOM_Formulation_Id]) REFERENCES [dbo].[Bill_Of_Material_Formulation] ([BOM_Formulation_Id]),
    CONSTRAINT [BOMFormulationItem_FK_EngUnitId] FOREIGN KEY ([Eng_Unit_Id]) REFERENCES [dbo].[Engineering_Unit] ([Eng_Unit_Id]),
    CONSTRAINT [BOMFormulationItem_FK_LocationId] FOREIGN KEY ([Location_Id]) REFERENCES [dbo].[Unit_Locations] ([Location_Id]),
    CONSTRAINT [BOMFormulationItem_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [BOMFormulationItem_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [BOMFormulationItem_UC_FormulationIdFormulationOrder] UNIQUE NONCLUSTERED ([BOM_Formulation_Id] ASC, [BOM_Formulation_Order] ASC)
);


GO
CREATE TRIGGER [dbo].[Bill_Of_Material_Formulation_Item_TableFieldValue_Del]
 ON  [dbo].[Bill_Of_Material_Formulation_Item]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.BOM_Formulation_Item_Id
 WHERE tfv.TableId = 28
