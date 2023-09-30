CREATE TABLE [dbo].[WebService] (
    [WebServiceId]                UNIQUEIDENTIFIER NOT NULL,
    [Name]                        NVARCHAR (255)   NULL,
    [Description]                 NVARCHAR (255)   NULL,
    [WsdlUrl]                     NVARCHAR (2000)  NULL,
    [ServiceBindingConfiguration] NVARCHAR (MAX)   NULL,
    [RefreshRequired]             BIT              NULL,
    [WsdlContentHash]             NVARCHAR (MAX)   NULL,
    [NamespaceName]               NVARCHAR (255)   NULL,
    [Version]                     BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([WebServiceId] ASC)
);

