CREATE TABLE [dbo].[Sheet_Shortcuts] (
    [Sheet_Shortcut_Id]   INT          IDENTITY (1, 1) NOT NULL,
    [Group_Id]            INT          NOT NULL,
    [Sheet_Shortcut_Desc] VARCHAR (50) NOT NULL,
    [Sheet_Shortcut_SP]   VARCHAR (50) NOT NULL,
    CONSTRAINT [Sheet_Shortcuts_FK_Security_Groups] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [ShtShortcuts_PK_ShtShortcutDesc] UNIQUE NONCLUSTERED ([Sheet_Shortcut_Desc] ASC),
    CONSTRAINT [ShtShortcuts_PK_ShtShortcutId] UNIQUE CLUSTERED ([Sheet_Shortcut_Id] ASC)
);

