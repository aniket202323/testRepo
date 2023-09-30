CREATE TABLE [dbo].[QFDataTypePhrases] (
    [DataTypeId]                UNIQUEIDENTIFIER NOT NULL,
    [DataTypePhraseId]          UNIQUEIDENTIFIER NOT NULL,
    [DataTypePhraseName]        NVARCHAR (50)    NOT NULL,
    [DataTypePhraseDescription] NVARCHAR (255)   NULL,
    [SortOrder]                 INT              DEFAULT ((1)) NOT NULL,
    [Version]                   BIGINT           NULL,
    CONSTRAINT [PK_QFDataTypePhrases] PRIMARY KEY CLUSTERED ([DataTypePhraseId] ASC),
    CONSTRAINT [FK_QFDataTypePhrases_QFDataTypes] FOREIGN KEY ([DataTypeId]) REFERENCES [dbo].[QFDataTypes] ([DataTypeId]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [NC_QFDataTypePhrases_DataTypeId]
    ON [dbo].[QFDataTypePhrases]([DataTypeId] ASC, [DataTypePhraseName] ASC);

