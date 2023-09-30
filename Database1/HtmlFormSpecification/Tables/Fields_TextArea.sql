CREATE TABLE [HtmlFormSpecification].[Fields_TextArea] (
    [MaxLength]    INT            NULL,
    [NumLines]     INT            NULL,
    [DefaultValue] NVARCHAR (MAX) NULL,
    [Id]           INT            NOT NULL,
    CONSTRAINT [PK_Fields_TextArea] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_TextArea_inherits_Input] FOREIGN KEY ([Id]) REFERENCES [HtmlFormSpecification].[Fields_Input] ([Id]) ON DELETE CASCADE
);

