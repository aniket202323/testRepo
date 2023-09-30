CREATE TABLE [dbo].[OldestDiscardedDataChange] (
    [PersistenceLevel]     TINYINT          NOT NULL,
    [TimeStamp]            BIGINT           NULL,
    [Version]              BIGINT           NULL,
    [ProducerConnectionId] UNIQUEIDENTIFIER NOT NULL,
    [DtlNodeId]            UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ProducerConnectionId] ASC, [DtlNodeId] ASC, [PersistenceLevel] ASC),
    CONSTRAINT [OldestDiscardedDataChange_DtlNode_Relation1] FOREIGN KEY ([DtlNodeId]) REFERENCES [dbo].[DtlNode] ([DtlNodeId]),
    CONSTRAINT [OldestDiscardedDataChange_ProducerConnection_Relation1] FOREIGN KEY ([ProducerConnectionId]) REFERENCES [dbo].[ProducerConnection] ([ProducerConnectionId])
);


GO
CREATE NONCLUSTERED INDEX [NC_OldestDiscardedDataChange_DtlNodeId]
    ON [dbo].[OldestDiscardedDataChange]([DtlNodeId] ASC);

