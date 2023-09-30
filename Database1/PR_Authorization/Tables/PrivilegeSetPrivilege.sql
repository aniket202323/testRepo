CREATE TABLE [PR_Authorization].[PrivilegeSetPrivilege] (
    [PrivilegeSetPrivilegeId] UNIQUEIDENTIFIER NOT NULL,
    [PrivilegeSetId]          UNIQUEIDENTIFIER NOT NULL,
    [PrivilegeId]             UNIQUEIDENTIFIER NOT NULL,
    [Version]                 BIGINT           NOT NULL,
    [CreatedBy]               NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]             DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]          NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate]        DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_PrivilegeSetPrivilege] PRIMARY KEY CLUSTERED ([PrivilegeSetPrivilegeId] ASC),
    CONSTRAINT [FK_PrivilegeSetPrivilege_Privilege] FOREIGN KEY ([PrivilegeId]) REFERENCES [PR_Authorization].[Privilege] ([PrivilegeId]),
    CONSTRAINT [FK_PrivilegeSetPrivilege_PrivilegeSet] FOREIGN KEY ([PrivilegeSetId]) REFERENCES [PR_Authorization].[PrivilegeSet] ([PrivilegeSetId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_RolePrivilege]
    ON [PR_Authorization].[PrivilegeSetPrivilege]([PrivilegeSetId] ASC, [PrivilegeId] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This contains the individual privileges included in a Privilege Set.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'PrivilegeSetPrivilege';

