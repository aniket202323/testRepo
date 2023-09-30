CREATE TABLE [HtmlFormSpecification].[Fields_ListBox] (
    [Id] INT NOT NULL,
    CONSTRAINT [PK_Fields_ListBox] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ListBox_inherits_Selection] FOREIGN KEY ([Id]) REFERENCES [HtmlFormSpecification].[Fields_Selection] ([Id]) ON DELETE CASCADE
);

