CREATE TABLE [dbo].[ProducerConnection] (
    [ProducerConnectionId]       UNIQUEIDENTIFIER NOT NULL,
    [IpAddress]                  NVARCHAR (255)   NULL,
    [Port]                       SMALLINT         NULL,
    [SecureCerticate]            NVARCHAR (255)   NULL,
    [HoldbackTime]               SMALLINT         NULL,
    [DisconnectTimeout]          INT              NULL,
    [DisconnectChangeQueueLimit] INT              NULL,
    [KeepAlivePeriod]            INT              NULL,
    [MinimumPersistenceLevel]    TINYINT          NULL,
    [MaximumPacketSize]          INT              NULL,
    [Version]                    BIGINT           NULL,
    [DtlNodeId]                  UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ProducerConnectionId] ASC),
    CONSTRAINT [ProducerConnection_DtlNode_Relation1] FOREIGN KEY ([DtlNodeId]) REFERENCES [dbo].[DtlNode] ([DtlNodeId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ProducerConnection_DtlNodeId]
    ON [dbo].[ProducerConnection]([DtlNodeId] ASC);

