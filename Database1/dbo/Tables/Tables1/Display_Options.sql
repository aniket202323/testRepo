CREATE TABLE [dbo].[Display_Options] (
    [Display_Option_Id]          INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Display_Option_Access_Id]   INT                       CONSTRAINT [DF_Display_Options_Display_Option_Access_Id] DEFAULT ((1)) NOT NULL,
    [Display_Option_Category_Id] INT                       NULL,
    [Display_Option_Desc]        [dbo].[Varchar_Desc]      NOT NULL,
    [Display_Option_Long_Desc]   [dbo].[Varchar_Long_Desc] NULL,
    [Field_Type_Id]              INT                       NULL,
    [Is_Esignature]              TINYINT                   NULL,
    CONSTRAINT [DisplayOpt_PK_DispOptId] PRIMARY KEY NONCLUSTERED ([Display_Option_Id] ASC),
    CONSTRAINT [Display_Option_FK_Display_Option_Access_Id] FOREIGN KEY ([Display_Option_Access_Id]) REFERENCES [dbo].[Display_Option_Access] ([Display_Option_Access_Id]),
    CONSTRAINT [DisplayOptionS_FK_DisplayOptionCategoryId] FOREIGN KEY ([Display_Option_Category_Id]) REFERENCES [dbo].[Display_Option_Categories] ([Display_Option_Category_Id]),
    CONSTRAINT [DisplayOptions_FK_FieldType] FOREIGN KEY ([Field_Type_Id]) REFERENCES [dbo].[ED_FieldTypes] ([ED_Field_Type_Id]),
    CONSTRAINT [DisplayOpt_UC_DispOptDescCatId] UNIQUE CLUSTERED ([Display_Option_Desc] ASC, [Display_Option_Category_Id] ASC)
);

