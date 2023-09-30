CREATE TABLE [dbo].[Color_Scheme_Data] (
    [Color_Scheme_Field_Id] INT NOT NULL,
    [Color_Scheme_Value]    INT NULL,
    [CS_Id]                 INT NOT NULL,
    CONSTRAINT [ColorSchemeData_PK_CSId_ColorSchemeFieldId] PRIMARY KEY NONCLUSTERED ([CS_Id] ASC, [Color_Scheme_Field_Id] ASC),
    CONSTRAINT [ColorSchemeData_FK_ColorScheme] FOREIGN KEY ([CS_Id]) REFERENCES [dbo].[Color_Scheme] ([CS_Id]),
    CONSTRAINT [ColorSchemeData_FK_ColorSchemeFields] FOREIGN KEY ([Color_Scheme_Field_Id]) REFERENCES [dbo].[Color_Scheme_Fields] ([Color_Scheme_Field_Id])
);

