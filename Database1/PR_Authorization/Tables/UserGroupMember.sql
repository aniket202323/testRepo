CREATE TABLE [PR_Authorization].[UserGroupMember] (
    [UserGroupId]      UNIQUEIDENTIFIER NOT NULL,
    [UserAccountId]    UNIQUEIDENTIFIER NOT NULL,
    [Deleted]          BIT              DEFAULT ((0)) NOT NULL,
    [Version]          BIGINT           DEFAULT ((1)) NOT NULL,
    [CreatedBy]        NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]      DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]   NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate] DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_UserGroupMember] PRIMARY KEY CLUSTERED ([UserGroupId] ASC, [UserAccountId] ASC),
    CONSTRAINT [FK_UserGroupMember_UserAccount] FOREIGN KEY ([UserAccountId]) REFERENCES [PR_Authorization].[UserAccount] ([UserAccountId]),
    CONSTRAINT [FK_UserGroupMember_UserGroup] FOREIGN KEY ([UserGroupId]) REFERENCES [PR_Authorization].[UserGroup] ([UserGroupId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_UserGroupMember]
    ON [PR_Authorization].[UserGroupMember]([UserAccountId] ASC, [UserGroupId] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This is the list of Users that are contained within a User Group.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'UserGroupMember';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'If 1, the UserGroupMember record has been logically deleted.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'UserGroupMember', @level2type = N'COLUMN', @level2name = N'Deleted';

