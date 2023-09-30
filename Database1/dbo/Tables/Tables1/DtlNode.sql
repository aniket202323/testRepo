CREATE TABLE [dbo].[DtlNode] (
    [DtlNodeId]   UNIQUEIDENTIFIER NOT NULL,
    [DtlName]     NVARCHAR (255)   NULL,
    [RetryPeriod] INT              NULL,
    [Version]     BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([DtlNodeId] ASC)
);

