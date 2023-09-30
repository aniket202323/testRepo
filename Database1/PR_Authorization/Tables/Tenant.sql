CREATE TABLE [PR_Authorization].[Tenant] (
    [TenantId]         UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    [Name]             NVARCHAR (255)   NOT NULL,
    [Description]      NVARCHAR (MAX)   NULL,
    [Version]          INT              NOT NULL,
    [ParentTenantId]   UNIQUEIDENTIFIER NULL,
    [Deleted]          BIT              CONSTRAINT [DF_Tenant_Deleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]        NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]      DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]   NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate] DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_Tenant] PRIMARY KEY CLUSTERED ([TenantId] ASC),
    CONSTRAINT [FK_Tenant_Tenant] FOREIGN KEY ([ParentTenantId]) REFERENCES [PR_Authorization].[Tenant] ([TenantId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_Tenant]
    ON [PR_Authorization].[Tenant]([Name] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This identifies the different Tenants defined in the system. By default there will always be a root tenant (zero GUID).', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'Tenant';

