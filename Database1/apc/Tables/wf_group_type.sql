CREATE TABLE [apc].[wf_group_type] (
    [id]               INT           IDENTITY (1, 1) NOT NULL,
    [created_by]       VARCHAR (50)  NULL,
    [created_on]       DATETIME2 (7) NULL,
    [last_modified_by] VARCHAR (50)  NULL,
    [last_modified_on] DATETIME2 (7) NULL,
    [group_name]       VARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

