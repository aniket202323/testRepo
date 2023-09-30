CREATE TABLE [dbo].[Bill_Of_Material_Formulation] (
    [BOM_Formulation_Id]        BIGINT       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [BOM_Formulation_Code]      VARCHAR (25) NULL,
    [BOM_Formulation_Desc]      VARCHAR (50) NOT NULL,
    [BOM_Id]                    INT          NOT NULL,
    [Comment_Id]                INT          NULL,
    [Effective_Date]            DATETIME     NULL,
    [Eng_Unit_Id]               INT          NOT NULL,
    [Expiration_Date]           DATETIME     NULL,
    [Master_BOM_Formulation_Id] BIGINT       NULL,
    [Quantity_Precision]        INT          CONSTRAINT [BOMFormulation_DF_Precision] DEFAULT ((2)) NOT NULL,
    [Standard_Quantity]         FLOAT (53)   NOT NULL,
    CONSTRAINT [BOMFormulation_PK_Formulation_Id] PRIMARY KEY NONCLUSTERED ([BOM_Formulation_Id] ASC),
    CONSTRAINT [BOMFormulation_FK_BOMId] FOREIGN KEY ([BOM_Id]) REFERENCES [dbo].[Bill_Of_Material] ([BOM_Id]),
    CONSTRAINT [BOMFormulation_FK_EngUnitId] FOREIGN KEY ([Eng_Unit_Id]) REFERENCES [dbo].[Engineering_Unit] ([Eng_Unit_Id]),
    CONSTRAINT [BOMFormulation_FK_MasterFormulationId] FOREIGN KEY ([Master_BOM_Formulation_Id]) REFERENCES [dbo].[Bill_Of_Material_Formulation] ([BOM_Formulation_Id]),
    CONSTRAINT [BOMFormulation_UC_FormulationDesc] UNIQUE NONCLUSTERED ([BOM_Formulation_Desc] ASC)
);


GO
CREATE TRIGGER [dbo].[Bill_Of_Material_Formulation_TableFieldValue_Del]
 ON  [dbo].[Bill_Of_Material_Formulation]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.BOM_Formulation_Id
 WHERE tfv.TableId = 26
