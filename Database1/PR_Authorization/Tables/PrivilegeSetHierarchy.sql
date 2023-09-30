CREATE TABLE [PR_Authorization].[PrivilegeSetHierarchy] (
    [PrivilegeSetId]         UNIQUEIDENTIFIER NOT NULL,
    [IncludedPrivilegeSetId] UNIQUEIDENTIFIER NOT NULL,
    [Version]                BIGINT           NOT NULL,
    [CreatedBy]              NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]            DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]         NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate]       DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_PrivilegeSetHierarchy] PRIMARY KEY CLUSTERED ([PrivilegeSetId] ASC, [IncludedPrivilegeSetId] ASC),
    CONSTRAINT [FK_PrivilegeSetHierarchy_PrivilegeSet_IncludedPrivilegeSetId] FOREIGN KEY ([IncludedPrivilegeSetId]) REFERENCES [PR_Authorization].[PrivilegeSet] ([PrivilegeSetId]),
    CONSTRAINT [FK_PrivilegeSetHierarchy_PrivilegeSet_PrivilegeSetId] FOREIGN KEY ([PrivilegeSetId]) REFERENCES [PR_Authorization].[PrivilegeSet] ([PrivilegeSetId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_RoleHierarchy]
    ON [PR_Authorization].[PrivilegeSetHierarchy]([IncludedPrivilegeSetId] ASC, [PrivilegeSetId] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table will hold which Privilege Sets are "Included" in another Privilege Set. The Privilege set will be a union of all the includes privileges and included privilege sets.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'PrivilegeSetHierarchy';

