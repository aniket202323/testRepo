CREATE TABLE [dbo].[ServerInstance] (
    [Id]                INT            IDENTITY (1, 1) NOT NULL,
    [Name]              NVARCHAR (255) NULL,
    [Description]       NVARCHAR (255) NULL,
    [TcpPort]           INT            NULL,
    [HttpPort]          INT            NULL,
    [WSHttpPort]        INT            NULL,
    [HttpsUserPassPort] INT            NULL,
    [HttpsSamlPort]     INT            NULL,
    [DtlIpAddress]      NVARCHAR (255) NULL,
    [DtlPort]           INT            NULL,
    [ClusterHostName]   NVARCHAR (255) NULL,
    [IsSecurityServer]  BIT            NULL,
    [Version]           BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ServerInstance_Name]
    ON [dbo].[ServerInstance]([Name] ASC);

