CREATE TABLE [dbo].[WorkInstructionsKeyword] (
    [KeywordId]   UNIQUEIDENTIFIER NOT NULL,
    [KeywordName] NVARCHAR (255)   NOT NULL,
    [Version]     BIGINT           NULL,
    [Id]          UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([KeywordId] ASC),
    CONSTRAINT [WorkInstructionsKeyword_WorkInstructions_Relation1] FOREIGN KEY ([Id]) REFERENCES [dbo].[WorkInstructions] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_WorkInstructionsKeyword_Id]
    ON [dbo].[WorkInstructionsKeyword]([Id] ASC);

