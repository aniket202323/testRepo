CREATE TABLE [dbo].[Color_Scheme_Categories] (
    [Color_Scheme_Category_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Color_Scheme_Category_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [ColorSchemeCategories_PK_ColorSchemeCategoryId] PRIMARY KEY NONCLUSTERED ([Color_Scheme_Category_Id] ASC),
    CONSTRAINT [ColorSchemeCategories_UC_ColorSchemeCategoryDesc] UNIQUE NONCLUSTERED ([Color_Scheme_Category_Desc] ASC)
);

