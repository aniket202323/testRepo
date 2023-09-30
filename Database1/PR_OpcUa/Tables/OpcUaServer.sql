CREATE TABLE [PR_OpcUa].[OpcUaServer] (
    [ServerId]           UNIQUEIDENTIFIER NOT NULL,
    [Name]               NVARCHAR (255)   NOT NULL,
    [ServerURL]          NVARCHAR (255)   NULL,
    [ApplicationURI]     NVARCHAR (255)   NULL,
    [Description]        NVARCHAR (255)   NULL,
    [DiscoveryURL]       NVARCHAR (255)   NULL,
    [UserName]           NVARCHAR (255)   NULL,
    [Password]           NVARCHAR (255)   NULL,
    [SecureConnection]   BIT              DEFAULT ((0)) NOT NULL,
    [PublishingEnabled]  BIT              DEFAULT ((1)) NOT NULL,
    [OperationTimeout]   INT              NULL,
    [PublishingInterval] INT              NULL,
    [MaxKeepAliveTime]   INT              NULL,
    [Lifetime]           INT              NULL,
    [Version]            BIGINT           NULL,
    CONSTRAINT [PK_OpcUaServer] PRIMARY KEY CLUSTERED ([ServerId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_OpcUaServer_Name]
    ON [PR_OpcUa].[OpcUaServer]([Name] ASC);

