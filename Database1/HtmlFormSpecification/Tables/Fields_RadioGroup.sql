CREATE TABLE [HtmlFormSpecification].[Fields_RadioGroup] (
    [Id] INT NOT NULL,
    CONSTRAINT [PK_Fields_RadioGroup] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_RadioGroup_inherits_Selection] FOREIGN KEY ([Id]) REFERENCES [HtmlFormSpecification].[Fields_Selection] ([Id]) ON DELETE CASCADE
);

