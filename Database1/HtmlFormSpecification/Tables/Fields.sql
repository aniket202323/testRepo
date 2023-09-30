CREATE TABLE [HtmlFormSpecification].[Fields] (
    [Id]        INT            IDENTITY (1, 1) NOT NULL,
    [Name]      NVARCHAR (MAX) NOT NULL,
    [Label]     NVARCHAR (MAX) NULL,
    [Order]     INT            NOT NULL,
    [DisplayId] NVARCHAR (255) NOT NULL,
    CONSTRAINT [PK_Fields] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [DisplayDmc_Relation] FOREIGN KEY ([DisplayId]) REFERENCES [dbo].[DisplayDmc] ([DisplayDmcDisplayHierarchyDmcId]) ON DELETE CASCADE
);

