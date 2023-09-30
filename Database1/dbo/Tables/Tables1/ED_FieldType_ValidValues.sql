CREATE TABLE [dbo].[ED_FieldType_ValidValues] (
    [FTV_Id]           INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ED_Field_Type_Id] INT          NOT NULL,
    [Field_Desc]       VARCHAR (50) NOT NULL,
    [Field_Id]         TINYINT      NOT NULL,
    CONSTRAINT [PK_ED_FieldType_ValidValues] PRIMARY KEY CLUSTERED ([FTV_Id] ASC),
    CONSTRAINT [ED_FieldType_ValidValues_FK_FieldTypeId] FOREIGN KEY ([ED_Field_Type_Id]) REFERENCES [dbo].[ED_FieldTypes] ([ED_Field_Type_Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [FieldType_UC_FieldId]
    ON [dbo].[ED_FieldType_ValidValues]([ED_Field_Type_Id] ASC, [Field_Id] ASC);

