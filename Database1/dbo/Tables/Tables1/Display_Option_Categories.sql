CREATE TABLE [dbo].[Display_Option_Categories] (
    [Display_Option_Category_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Display_Option_Category_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [DisplayOptionCategories_PK_DisplayOptionCategoryId] PRIMARY KEY NONCLUSTERED ([Display_Option_Category_Id] ASC),
    CONSTRAINT [DisplayOptionCategories_UC_DisplayOptionCategoryDesc] UNIQUE NONCLUSTERED ([Display_Option_Category_Desc] ASC)
);

