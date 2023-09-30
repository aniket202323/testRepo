CREATE TABLE [dbo].[ServiceProviderLicense] (
    [LicenseId]          UNIQUEIDENTIFIER NOT NULL,
    [LicensableEndpoint] NVARCHAR (255)   NOT NULL,
    [LicenseType]        INT              NOT NULL,
    [Version]            BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([LicenseId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ServiceProviderLicense_LicensableEndpoint_LicenseType]
    ON [dbo].[ServiceProviderLicense]([LicensableEndpoint] ASC, [LicenseType] ASC);

