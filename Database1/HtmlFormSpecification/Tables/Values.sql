CREATE TABLE [HtmlFormSpecification].[Values] (
    [Id]          INT            IDENTITY (1, 1) NOT NULL,
    [Label]       NVARCHAR (MAX) NOT NULL,
    [Order]       INT            NOT NULL,
    [SelectionId] INT            NOT NULL,
    CONSTRAINT [PK_Values] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_SelectionValues] FOREIGN KEY ([SelectionId]) REFERENCES [HtmlFormSpecification].[Fields_Selection] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_FK_SelectionValues]
    ON [HtmlFormSpecification].[Values]([SelectionId] ASC);

