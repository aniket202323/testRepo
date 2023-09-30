CREATE TABLE [HtmlFormSpecification].[Fields_TextBox] (
    [Type]         INT            NOT NULL,
    [MaxLength]    INT            NULL,
    [MinValue]     INT            NULL,
    [MaxValue]     INT            NULL,
    [DefaultValue] NVARCHAR (MAX) NULL,
    [Id]           INT            NOT NULL,
    CONSTRAINT [PK_Fields_TextBox] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_TextBox_inherits_Input] FOREIGN KEY ([Id]) REFERENCES [HtmlFormSpecification].[Fields_Input] ([Id]) ON DELETE CASCADE
);

