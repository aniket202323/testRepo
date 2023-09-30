CREATE TABLE [dbo].[Producer] (
    [ProducerName]         NVARCHAR (255)   NULL,
    [ProducerId]           UNIQUEIDENTIFIER NOT NULL,
    [Version]              BIGINT           NULL,
    [ProducerConnectionId] UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ProducerId] ASC),
    CONSTRAINT [Producer_ProducerConnection_Relation1] FOREIGN KEY ([ProducerConnectionId]) REFERENCES [dbo].[ProducerConnection] ([ProducerConnectionId])
);


GO
CREATE NONCLUSTERED INDEX [NC_Producer_ProducerConnectionId]
    ON [dbo].[Producer]([ProducerConnectionId] ASC);

