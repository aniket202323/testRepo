CREATE TABLE [dbo].[ResultSetConfig] (
    [ActualPropertyName] VARCHAR (50) NULL,
    [ColumnNum]          INT          NOT NULL,
    [DefaultValue]       VARCHAR (50) NULL,
    [MsgPropertyId]      INT          NULL,
    [RSTId]              INT          NOT NULL,
    [UsedAsPropertyName] VARCHAR (50) NOT NULL,
    CONSTRAINT [ResultSetConfig_PK_RSTIdColumnNum] PRIMARY KEY CLUSTERED ([RSTId] ASC, [ColumnNum] ASC),
    CONSTRAINT [ResultSetConfig_FK_MessageProperties] FOREIGN KEY ([MsgPropertyId]) REFERENCES [dbo].[Message_Properties] ([MsgPropertyId]) ON DELETE CASCADE,
    CONSTRAINT [ResultSetConfig_FK_ResultSetTypes] FOREIGN KEY ([RSTId]) REFERENCES [dbo].[ResultSetTypes] ([RSTId]) ON DELETE CASCADE
);

