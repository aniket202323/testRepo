CREATE TABLE [PR_Authorization].[PrivilegeSet] (
    [PrivilegeSetId]   UNIQUEIDENTIFIER NOT NULL,
    [TenantId]         UNIQUEIDENTIFIER NOT NULL,
    [Name]             NVARCHAR (255)   NOT NULL,
    [Description]      NVARCHAR (255)   NULL,
    [Version]          BIGINT           NOT NULL,
    [Deleted]          BIT              CONSTRAINT [DF_PrivilegeSet_Deleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]        NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]      DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]   NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate] DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_PrivilegeSet] PRIMARY KEY CLUSTERED ([PrivilegeSetId] ASC),
    CONSTRAINT [FK_PrivilegeSet_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [PR_Authorization].[Tenant] ([TenantId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_Role]
    ON [PR_Authorization].[PrivilegeSet]([TenantId] ASC, [Name] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table contains the List of Privilege Sets defined. It is equivant to the old Role.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'PrivilegeSet';

