CREATE TABLE [dbo].[Sheet_Shortcut_Data] (
    [Group_Id]          INT NULL,
    [Sheet_Id]          INT NOT NULL,
    [Sheet_Shortcut_Id] INT NOT NULL,
    CONSTRAINT [Sheet_Shortcut_Data_FK_Sheet_Shortcuts] FOREIGN KEY ([Sheet_Shortcut_Id]) REFERENCES [dbo].[Sheet_Shortcuts] ([Sheet_Shortcut_Id]),
    CONSTRAINT [Sheet_Shortcut_Data_FK_Sheets] FOREIGN KEY ([Sheet_Id]) REFERENCES [dbo].[Sheets] ([Sheet_Id]),
    CONSTRAINT [ShtShortcutData_PK_ShtIdShtShortcutId] UNIQUE CLUSTERED ([Sheet_Id] ASC, [Sheet_Shortcut_Id] ASC)
);

