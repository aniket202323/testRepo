CREATE TABLE [dbo].[Sheet_Genealogy_Data] (
    [Display_Sheet_Id] INT NOT NULL,
    [PU_Id]            INT NOT NULL,
    [Sheet_Id]         INT NOT NULL,
    CONSTRAINT [Sheet_Genealogy_Data_PK_SheetIdPUId] PRIMARY KEY CLUSTERED ([Sheet_Id] ASC, [PU_Id] ASC),
    CONSTRAINT [FK_Sheet_Genealogy_Data_Prod_Units] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [FK_Sheet_Genealogy_Data_Sheets] FOREIGN KEY ([Sheet_Id]) REFERENCES [dbo].[Sheets] ([Sheet_Id]),
    CONSTRAINT [FK_Sheet_Genealogy_Data_Sheets1] FOREIGN KEY ([Display_Sheet_Id]) REFERENCES [dbo].[Sheets] ([Sheet_Id])
);

