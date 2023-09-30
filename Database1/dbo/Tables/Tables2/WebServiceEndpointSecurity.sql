CREATE TABLE [dbo].[WebServiceEndpointSecurity] (
    [EndpointId]        UNIQUEIDENTIFIER NOT NULL,
    [EndpointName]      NVARCHAR (255)   NULL,
    [Address]           NVARCHAR (2000)  NULL,
    [Binding]           NVARCHAR (255)   NULL,
    [ContractName]      NVARCHAR (255)   NULL,
    [UserName]          NVARCHAR (255)   NULL,
    [Password]          NVARCHAR (255)   NULL,
    [StoreName]         NVARCHAR (255)   NULL,
    [StoreLocation]     NVARCHAR (255)   NULL,
    [X509FindType]      NVARCHAR (255)   NULL,
    [X509FindTypeValue] NVARCHAR (255)   NULL,
    [Version]           BIGINT           NULL,
    [WebServiceId]      UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([EndpointId] ASC),
    CONSTRAINT [WebServiceEndpointSecurity_WebService_Relation1] FOREIGN KEY ([WebServiceId]) REFERENCES [dbo].[WebService] ([WebServiceId])
);


GO
CREATE NONCLUSTERED INDEX [NC_WebServiceEndpointSecurity_WebServiceId]
    ON [dbo].[WebServiceEndpointSecurity]([WebServiceId] ASC);

