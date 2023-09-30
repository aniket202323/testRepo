CREATE TABLE [dbo].[Sheet_Paths] (
    [Path_Id]  INT NOT NULL,
    [Sheet_Id] INT NOT NULL,
    CONSTRAINT [SheetPaths_PK_SheetIdPathId] PRIMARY KEY NONCLUSTERED ([Sheet_Id] ASC, [Path_Id] ASC),
    CONSTRAINT [SheetPath_FK_SheetId] FOREIGN KEY ([Sheet_Id]) REFERENCES [dbo].[Sheets] ([Sheet_Id]),
    CONSTRAINT [SheetPaths_FK_PathId] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id])
);

