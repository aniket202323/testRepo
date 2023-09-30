CREATE TABLE [apc].[wf_level_group_security_group_configuration] (
    [id]                          BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]                  VARCHAR (50)  NULL,
    [created_on]                  DATETIME2 (7) NULL,
    [last_modified_by]            VARCHAR (50)  NULL,
    [last_modified_on]            DATETIME2 (7) NULL,
    [wf_group_security_config_id] BIGINT        NULL,
    [wf_level_group_config_id]    BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([wf_group_security_config_id]) REFERENCES [apc].[wf_group_type_security_configuration] ([id]),
    FOREIGN KEY ([wf_level_group_config_id]) REFERENCES [apc].[wf_level_group_configuration] ([id])
);

