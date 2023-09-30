CREATE TABLE [dbo].[UnacknowledgedDataChangePacket] (
    [PersistenceLevel] TINYINT          NOT NULL,
    [PacketId]         BIGINT           NOT NULL,
    [PacketContent]    IMAGE            NULL,
    [Version]          BIGINT           NULL,
    [ProducerId]       UNIQUEIDENTIFIER NOT NULL,
    [DtlNodeId]        UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ProducerId] ASC, [DtlNodeId] ASC, [PersistenceLevel] ASC, [PacketId] ASC),
    CONSTRAINT [UnacknowledgedDataChangePacket_DtlNode_Relation1] FOREIGN KEY ([DtlNodeId]) REFERENCES [dbo].[DtlNode] ([DtlNodeId]),
    CONSTRAINT [UnacknowledgedDataChangePacket_Producer_Relation1] FOREIGN KEY ([ProducerId]) REFERENCES [dbo].[Producer] ([ProducerId])
);


GO
CREATE NONCLUSTERED INDEX [NC_UnacknowledgedDataChangePacket_DtlNodeId]
    ON [dbo].[UnacknowledgedDataChangePacket]([DtlNodeId] ASC);

