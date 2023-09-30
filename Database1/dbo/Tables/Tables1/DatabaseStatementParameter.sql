CREATE TABLE [dbo].[DatabaseStatementParameter] (
    [Name]              NVARCHAR (128)   NOT NULL,
    [ParameterTypeName] NVARCHAR (255)   NULL,
    [Direction]         NVARCHAR (255)   NULL,
    [Version]           BIGINT           NULL,
    [Id]                UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([Name] ASC, [Id] ASC),
    CONSTRAINT [DatabaseStatementParameter_DatabaseStatement_Relation1] FOREIGN KEY ([Id]) REFERENCES [dbo].[DatabaseStatement] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_DatabaseStatementParameter_Id]
    ON [dbo].[DatabaseStatementParameter]([Id] ASC);

