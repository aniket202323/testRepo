CREATE TABLE [apc].[wf_group_type_security_configuration] (
    [id]                 BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]         VARCHAR (50)  NULL,
    [created_on]         DATETIME2 (7) NULL,
    [last_modified_by]   VARCHAR (50)  NULL,
    [last_modified_on]   DATETIME2 (7) NULL,
    [security_groupName] VARCHAR (255) NULL,
    [wf_group_type_id]   INT           NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([wf_group_type_id]) REFERENCES [apc].[wf_group_type] ([id]),
    CONSTRAINT [U_WF_GRTN_WF_GROUP_TYPE_ID] UNIQUE NONCLUSTERED ([wf_group_type_id] ASC, [security_groupName] ASC)
);

