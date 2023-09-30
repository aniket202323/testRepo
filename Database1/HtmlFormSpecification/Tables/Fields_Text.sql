CREATE TABLE [HtmlFormSpecification].[Fields_Text] (
    [Alignment] INT NOT NULL,
    [Size]      INT NOT NULL,
    [Id]        INT NOT NULL,
    CONSTRAINT [PK_Fields_Text] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Text_inherits_Field] FOREIGN KEY ([Id]) REFERENCES [HtmlFormSpecification].[Fields] ([Id]) ON DELETE CASCADE
);

