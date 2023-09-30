CREATE TABLE [dbo].[ADGroupAndChildGroup] (
    [r_Order]                    INT              NULL,
    [Version]                    BIGINT           NULL,
    [AdGroupAdGroupId]           UNIQUEIDENTIFIER NOT NULL,
    [AdChildGroupAdChildGroupId] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([AdGroupAdGroupId] ASC, [AdChildGroupAdChildGroupId] ASC),
    CONSTRAINT [ADGroupAndChildGroup_ActiveDirectoryChildGroup_Relation1] FOREIGN KEY ([AdChildGroupAdChildGroupId]) REFERENCES [dbo].[ActiveDirectoryChildGroup] ([AdChildGroupId]),
    CONSTRAINT [ADGroupAndChildGroup_ActiveDirectoryGroup_Relation1] FOREIGN KEY ([AdGroupAdGroupId]) REFERENCES [dbo].[ActiveDirectoryGroup] ([AdGroupId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ADGroupAndChildGroup_AdChildGroupAdChildGroupId]
    ON [dbo].[ADGroupAndChildGroup]([AdChildGroupAdChildGroupId] ASC);

