CREATE TABLE [apc].[wf_level_group_configuration] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]       VARCHAR (50)  NULL,
    [created_on]       DATETIME2 (7) NULL,
    [last_modified_by] VARCHAR (50)  NULL,
    [last_modified_on] DATETIME2 (7) NULL,
    [group_name]       VARCHAR (255) NOT NULL,
    [level_id]         INT           NOT NULL,
    [level_name]       VARCHAR (255) NOT NULL,
    [wf_config_id]     BIGINT        NULL,
    [wf_group_type_id] INT           NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([wf_config_id]) REFERENCES [apc].[wf_configuration] ([id]),
    CONSTRAINT [fk_wf_level_group_configuration_wf_group_type_id_wf_group_type_id] FOREIGN KEY ([wf_group_type_id]) REFERENCES [apc].[wf_group_type] ([id])
);

