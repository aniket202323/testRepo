CREATE TABLE [dbo].[AuditTopicConfig] (
    [TypeId]          NVARCHAR (50) NOT NULL,
    [TopicId]         NVARCHAR (50) NOT NULL,
    [IsAlwaysEnabled] BIT           NULL,
    [IsAuditEnabled]  BIT           NULL,
    [Version]         BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([TypeId] ASC, [TopicId] ASC)
);

