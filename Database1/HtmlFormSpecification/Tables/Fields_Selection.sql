CREATE TABLE [HtmlFormSpecification].[Fields_Selection] (
    [DefaultSelection] INT NULL,
    [Id]               INT NOT NULL,
    CONSTRAINT [PK_Fields_Selection] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Selection_inherits_Input] FOREIGN KEY ([Id]) REFERENCES [HtmlFormSpecification].[Fields_Input] ([Id]) ON DELETE CASCADE
);

