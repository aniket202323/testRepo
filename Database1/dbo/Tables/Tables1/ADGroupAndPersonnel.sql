CREATE TABLE [dbo].[ADGroupAndPersonnel] (
    [r_Order]               INT              NULL,
    [Version]               BIGINT           NULL,
    [ADGroupAdGroupId]      UNIQUEIDENTIFIER NOT NULL,
    [PersonnelGroupIdGroup] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ADGroupAdGroupId] ASC, [PersonnelGroupIdGroup] ASC),
    CONSTRAINT [ADGroupAndPersonnel_ActiveDirectoryGroup_Relation1] FOREIGN KEY ([ADGroupAdGroupId]) REFERENCES [dbo].[ActiveDirectoryGroup] ([AdGroupId]),
    CONSTRAINT [ADGroupAndPersonnel_PersonnelGroup_Relation1] FOREIGN KEY ([PersonnelGroupIdGroup]) REFERENCES [PR_Authorization].[UserGroup] ([UserGroupId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ADGroupAndPersonnel_PersonnelGroupIdGroup]
    ON [dbo].[ADGroupAndPersonnel]([PersonnelGroupIdGroup] ASC);

