CREATE TABLE [HtmlFormSpecification].[Fields_Input] (
    [IsRequired] BIT NOT NULL,
    [Id]         INT NOT NULL,
    CONSTRAINT [PK_Fields_Input] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Input_inherits_Field] FOREIGN KEY ([Id]) REFERENCES [HtmlFormSpecification].[Fields] ([Id]) ON DELETE CASCADE
);

