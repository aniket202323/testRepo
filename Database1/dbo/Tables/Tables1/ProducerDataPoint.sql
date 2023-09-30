CREATE TABLE [dbo].[ProducerDataPoint] (
    [PhysicalUrid] BIGINT           NOT NULL,
    [LogicalUrl]   NVARCHAR (1024)  NULL,
    [Version]      BIGINT           NULL,
    [ProducerId]   UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([PhysicalUrid] ASC, [ProducerId] ASC),
    CONSTRAINT [ProducerDataPoint_Producer_Relation1] FOREIGN KEY ([ProducerId]) REFERENCES [dbo].[Producer] ([ProducerId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ProducerDataPoint_ProducerId]
    ON [dbo].[ProducerDataPoint]([ProducerId] ASC);

