CREATE TABLE [dbo].[Bill_Of_Material_Family] (
    [BOM_Family_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [BOM_Family_Desc] VARCHAR (50) NOT NULL,
    [Comment_Id]      INT          NULL,
    [Group_Id]        INT          NULL,
    CONSTRAINT [BOMFamily_PK_BOMFamilyId] PRIMARY KEY NONCLUSTERED ([BOM_Family_Id] ASC),
    CONSTRAINT [BOMFamily_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [BOMFamily_UC_BOMFamilyDesc] UNIQUE NONCLUSTERED ([BOM_Family_Desc] ASC)
);

