CREATE TABLE [dbo].[Parameter_Categories] (
    [Parameter_Category_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Parameter_Category_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [ParameterCategories_PK_ParameterCategoryId] PRIMARY KEY NONCLUSTERED ([Parameter_Category_Id] ASC),
    CONSTRAINT [ParameterCategories_UC_ParameterCategoryDesc] UNIQUE NONCLUSTERED ([Parameter_Category_Desc] ASC)
);

