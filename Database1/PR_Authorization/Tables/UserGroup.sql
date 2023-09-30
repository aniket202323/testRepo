CREATE TABLE [PR_Authorization].[UserGroup] (
    [UserGroupId]      UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    [TenantId]         UNIQUEIDENTIFIER DEFAULT ([PR_Authorization].[ufn_GetDefaultTenant]()) NOT NULL,
    [Name]             NVARCHAR (255)   NOT NULL,
    [Description]      NVARCHAR (255)   NULL,
    [Type]             VARCHAR (255)    NULL,
    [Deleted]          BIT              CONSTRAINT [DF_UserGroup_Deleted] DEFAULT ((0)) NOT NULL,
    [Version]          BIGINT           DEFAULT ((1)) NOT NULL,
    [CreatedBy]        NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]      DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]   NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate] DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_UserGroup] PRIMARY KEY CLUSTERED ([UserGroupId] ASC),
    CONSTRAINT [FK_UserGroup_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [PR_Authorization].[Tenant] ([TenantId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_UserGroup]
    ON [PR_Authorization].[UserGroup]([TenantId] ASC, [Name] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This will contain the User Groups defined. A User Group is just a simple way to add, remove or change privileges for a user.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'UserGroup';

