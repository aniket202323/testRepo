CREATE TABLE [dbo].[UnsentDataChange] (
    [Data]               IMAGE            NULL,
    [PersistenceLevel]   TINYINT          NULL,
    [Quality]            TINYINT          NULL,
    [TimeStamp]          BIGINT           NULL,
    [UnsentDataChangeId] UNIQUEIDENTIFIER NOT NULL,
    [Version]            BIGINT           NULL,
    [DtlNodeId]          UNIQUEIDENTIFIER NULL,
    [PhysicalUrid]       BIGINT           NULL,
    [ProducerId]         UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([UnsentDataChangeId] ASC),
    CONSTRAINT [UnsentDataChange_DtlNode_Relation1] FOREIGN KEY ([DtlNodeId]) REFERENCES [dbo].[DtlNode] ([DtlNodeId]),
    CONSTRAINT [UnsentDataChange_Producer_Relation1] FOREIGN KEY ([ProducerId]) REFERENCES [dbo].[Producer] ([ProducerId]),
    CONSTRAINT [UnsentDataChange_ProducerDataPoint_Relation1] FOREIGN KEY ([PhysicalUrid], [ProducerId]) REFERENCES [dbo].[ProducerDataPoint] ([PhysicalUrid], [ProducerId])
);


GO
CREATE NONCLUSTERED INDEX [NC_UnsentDataChange_DtlNodeId]
    ON [dbo].[UnsentDataChange]([DtlNodeId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_UnsentDataChange_PhysicalUrid_ProducerId]
    ON [dbo].[UnsentDataChange]([PhysicalUrid] ASC, [ProducerId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_UnsentDataChange_ProducerId]
    ON [dbo].[UnsentDataChange]([ProducerId] ASC);

