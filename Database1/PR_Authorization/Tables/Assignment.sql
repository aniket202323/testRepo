CREATE TABLE [PR_Authorization].[Assignment] (
    [AssignmentId]     UNIQUEIDENTIFIER NOT NULL,
    [PrivilegeSetId]   UNIQUEIDENTIFIER NOT NULL,
    [ResourceSetId]    UNIQUEIDENTIFIER NOT NULL,
    [UserAccountId]    UNIQUEIDENTIFIER NULL,
    [UserGroupId]      UNIQUEIDENTIFIER NULL,
    [Deleted]          BIT              DEFAULT ((0)) NOT NULL,
    [Version]          BIGINT           NOT NULL,
    [CreatedBy]        NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]      DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]   NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate] DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_Assignment] PRIMARY KEY CLUSTERED ([AssignmentId] ASC),
    CONSTRAINT [FK_Assignment_PrivilegeSet] FOREIGN KEY ([PrivilegeSetId]) REFERENCES [PR_Authorization].[PrivilegeSet] ([PrivilegeSetId]),
    CONSTRAINT [FK_Assignment_ResourceSet] FOREIGN KEY ([ResourceSetId]) REFERENCES [PR_Authorization].[ResourceSet] ([ResourceSetId]),
    CONSTRAINT [FK_Assignment_UserAccount] FOREIGN KEY ([UserAccountId]) REFERENCES [PR_Authorization].[UserAccount] ([UserAccountId]),
    CONSTRAINT [FK_Assignment_UserGroup] FOREIGN KEY ([UserGroupId]) REFERENCES [PR_Authorization].[UserGroup] ([UserGroupId])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This will identify the Who, What, and How identified in RBAC Security. Who is identified by a UserAccount or a User Group. What is identified by a ResourceSet. How is identified by a PrivilegeSet.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'Assignment';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'If the Assignment is not Resource-based the ''Not Applicable'' ResourceSetId (GUID 00000000-0000-0000-0000-000000000001) will be used.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'Assignment', @level2type = N'COLUMN', @level2name = N'ResourceSetId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'FK to UserAccount.UserAccountId. One of UserAccountId or UserGroupId must be specified.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'Assignment', @level2type = N'COLUMN', @level2name = N'UserAccountId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'FK to UserGroup.UserGroupId One of UserAccountId or UserGroupId must be specified.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'Assignment', @level2type = N'COLUMN', @level2name = N'UserGroupId';

