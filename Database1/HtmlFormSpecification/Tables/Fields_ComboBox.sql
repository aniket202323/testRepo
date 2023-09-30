CREATE TABLE [HtmlFormSpecification].[Fields_ComboBox] (
    [Id] INT NOT NULL,
    CONSTRAINT [PK_Fields_ComboBox] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ComboBox_inherits_Selection] FOREIGN KEY ([Id]) REFERENCES [HtmlFormSpecification].[Fields_Selection] ([Id]) ON DELETE CASCADE
);

