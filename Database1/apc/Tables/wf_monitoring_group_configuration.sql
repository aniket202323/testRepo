CREATE TABLE [apc].[wf_monitoring_group_configuration] (
    [id]                          INT           IDENTITY (1, 1) NOT NULL,
    [created_by]                  VARCHAR (50)  NULL,
    [created_on]                  DATETIME2 (7) NULL,
    [last_modified_by]            VARCHAR (50)  NULL,
    [last_modified_on]            DATETIME2 (7) NULL,
    [name]                        VARCHAR (255) NULL,
    [wf_config_id]                BIGINT        NULL,
    [wf_group_security_config_id] BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([wf_config_id]) REFERENCES [apc].[wf_configuration] ([id]),
    FOREIGN KEY ([wf_group_security_config_id]) REFERENCES [apc].[wf_group_type_security_configuration] ([id])
);

