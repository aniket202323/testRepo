CREATE TABLE [HtmlFormSpecification].[Fields_CheckBox] (
    [DefaultChecked] BIT NOT NULL,
    [Id]             INT NOT NULL,
    CONSTRAINT [PK_Fields_CheckBox] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_CheckBox_inherits_Input] FOREIGN KEY ([Id]) REFERENCES [HtmlFormSpecification].[Fields_Input] ([Id]) ON DELETE CASCADE
);

