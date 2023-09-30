CREATE TABLE [dbo].[Color_Scheme_Fields] (
    [Color_Scheme_Field_Id]      INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Color_Scheme_Category_Id]   INT                  NOT NULL,
    [Color_Scheme_Field_Desc]    [dbo].[Varchar_Desc] NOT NULL,
    [Default_Color_Scheme_Color] INT                  NOT NULL,
    CONSTRAINT [ColorSchemeFields_PK_ColorSchemeFieldId] PRIMARY KEY NONCLUSTERED ([Color_Scheme_Field_Id] ASC),
    CONSTRAINT [ColorSchemeFields_FK_ColorSchemeCategoryId] FOREIGN KEY ([Color_Scheme_Category_Id]) REFERENCES [dbo].[Color_Scheme_Categories] ([Color_Scheme_Category_Id]),
    CONSTRAINT [ColorSchemeFields_UC_ColorSchemeFieldDesc] UNIQUE NONCLUSTERED ([Color_Scheme_Category_Id] ASC, [Color_Scheme_Field_Desc] ASC)
);

