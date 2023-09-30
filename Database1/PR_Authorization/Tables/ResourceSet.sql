CREATE TABLE [PR_Authorization].[ResourceSet] (
    [ResourceSetId]    UNIQUEIDENTIFIER NOT NULL,
    [TenantId]         UNIQUEIDENTIFIER NOT NULL,
    [Name]             NVARCHAR (255)   NOT NULL,
    [Description]      NVARCHAR (255)   NULL,
    [Type]             NVARCHAR (255)   NULL,
    [Version]          BIGINT           NOT NULL,
    [Deleted]          BIT              CONSTRAINT [DF_ResourceSet_Deleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]        NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]      DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]   NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate] DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_ResourceSet] PRIMARY KEY CLUSTERED ([ResourceSetId] ASC),
    CONSTRAINT [FK_ResourceSet_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [PR_Authorization].[Tenant] ([TenantId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_ResourceGroup]
    ON [PR_Authorization].[ResourceSet]([TenantId] ASC, [Name] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This is used to group together resources to identify the What part of RBAC security. Currently it is configured for Equipment, Displays, and Workflows.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'ResourceSet';

