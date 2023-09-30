CREATE TABLE [dbo].[Binaries] (
    [Binary_Id]      INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Binary_Desc]    VARCHAR (50) NOT NULL,
    [Field_Type_Id]  INT          NULL,
    [ForceOnInstall] BIT          NULL,
    [Image]          IMAGE        NULL,
    CONSTRAINT [PK_Binaries] PRIMARY KEY NONCLUSTERED ([Binary_Id] ASC),
    CONSTRAINT [Binaries_FK_FieldType] FOREIGN KEY ([Field_Type_Id]) REFERENCES [dbo].[ED_FieldTypes] ([ED_Field_Type_Id]),
    CONSTRAINT [Binaries_UC_Desc] UNIQUE NONCLUSTERED ([Binary_Desc] ASC)
);

