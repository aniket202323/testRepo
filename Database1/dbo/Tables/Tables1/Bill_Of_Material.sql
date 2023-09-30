CREATE TABLE [dbo].[Bill_Of_Material] (
    [BOM_Id]        INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [BOM_Desc]      VARCHAR (50) NOT NULL,
    [BOM_Family_Id] INT          NOT NULL,
    [Comment_Id]    INT          NULL,
    [Group_Id]      INT          NULL,
    [Is_Active]     BIT          CONSTRAINT [BOM_DF_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [BOM_PK_BOMId] PRIMARY KEY NONCLUSTERED ([BOM_Id] ASC),
    CONSTRAINT [BOM_FK_BOMFamilyId] FOREIGN KEY ([BOM_Family_Id]) REFERENCES [dbo].[Bill_Of_Material_Family] ([BOM_Family_Id]),
    CONSTRAINT [BOM_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [BOM_UC_BOMDesc] UNIQUE NONCLUSTERED ([BOM_Desc] ASC)
);


GO
CREATE TRIGGER [dbo].[Bill_Of_Material_TableFieldValue_Del]
 ON  [dbo].[Bill_Of_Material]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.BOM_Id
 WHERE tfv.TableId = 53
