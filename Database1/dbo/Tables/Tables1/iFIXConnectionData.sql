CREATE TABLE [dbo].[iFIXConnectionData] (
    [iFIXConnectionUId]       UNIQUEIDENTIFIER NOT NULL,
    [ConnectionName]          NVARCHAR (50)    NULL,
    [Description]             NVARCHAR (255)   NULL,
    [ScadaNode]               NVARCHAR (16)    NULL,
    [Username]                NVARCHAR (22)    NULL,
    [EncryptedPassword]       IMAGE            NULL,
    [Timeout]                 INT              NULL,
    [ServerPort]              INT              NULL,
    [SecurityMode]            NVARCHAR (32)    NULL,
    [TcpClientCredentialType] NVARCHAR (32)    NULL,
    [ProtectionLevel]         NVARCHAR (32)    NULL,
    [CertLocationType]        INT              NULL,
    [StoreLocation]           NVARCHAR (32)    NULL,
    [StoreName]               NVARCHAR (32)    NULL,
    [x509FindCriteria]        NVARCHAR (32)    NULL,
    [SubjectName]             NVARCHAR (255)   NULL,
    [CertFilePath]            NVARCHAR (100)   NULL,
    [Version]                 BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([iFIXConnectionUId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_iFIXConnectionData_ConnectionName]
    ON [dbo].[iFIXConnectionData]([ConnectionName] ASC);

