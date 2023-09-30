CREATE TABLE [dbo].[Email_Server] (
    [Id]                   UNIQUEIDENTIFIER NOT NULL,
    [Host]                 NVARCHAR (255)   NOT NULL,
    [Port]                 INT              NULL,
    [Timeout]              INT              NULL,
    [UserName]             NVARCHAR (255)   NULL,
    [Password]             NVARCHAR (255)   NULL,
    [SslEnabled]           BIT              DEFAULT ((0)) NOT NULL,
    [DefaultSenderAddress] NVARCHAR (255)   NULL,
    [DefaultSenderName]    NVARCHAR (255)   NULL,
    [Version]              BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

