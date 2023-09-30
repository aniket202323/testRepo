CREATE TABLE [dbo].[Bill_Of_Material_Formulation_Revision] (
    [BOM_Formulation_Revision_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [BOM_Formulation_Id]          BIGINT        NOT NULL,
    [Revision]                    INT           NOT NULL,
    [BOM_Formulation_Desc]        NVARCHAR (50) NOT NULL,
    [Status]                      NVARCHAR (25) NULL,
    [Created_By]                  NVARCHAR (50) NULL,
    [Created_On]                  DATETIME      NULL,
    [Last_Modified_By]            NVARCHAR (50) NULL,
    [Last_Modified_On]            DATETIME      NULL,
    CONSTRAINT [BOMFormulationRevision_FK_BOMFormulationId] FOREIGN KEY ([BOM_Formulation_Id]) REFERENCES [dbo].[Bill_Of_Material_Formulation] ([BOM_Formulation_Id])
);

