CREATE TABLE [dbo].[StructuredType] (
    [Namespace]             NVARCHAR (255)   NOT NULL,
    [Name]                  NVARCHAR (255)   NOT NULL,
    [Id]                    UNIQUEIDENTIFIER NULL,
    [Description]           NVARCHAR (255)   NULL,
    [IsPrivate]             BIT              NULL,
    [RecordPropertyHistory] BIT              NULL,
    [Version]               BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Namespace] ASC, [Name] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_StructuredType_Id]
    ON [dbo].[StructuredType]([Id] ASC);

