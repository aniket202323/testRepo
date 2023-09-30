CREATE TABLE [HtmlFormSpecification].[Fields_Image] (
    [Url]       NVARCHAR (MAX) NULL,
    [Height]    INT            NULL,
    [Width]     INT            NULL,
    [Alignment] INT            NOT NULL,
    [Id]        INT            NOT NULL,
    CONSTRAINT [PK_Fields_Image] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Image_inherits_Field] FOREIGN KEY ([Id]) REFERENCES [HtmlFormSpecification].[Fields] ([Id]) ON DELETE CASCADE
);

