CREATE TABLE [apc].[wf_escalation_configuration] (
    [id]                       INT           IDENTITY (1, 1) NOT NULL,
    [wf_level_group_config_id] BIGINT        NULL,
    [escalation_due_days]      INT           NULL,
    [created_by]               VARCHAR (50)  NULL,
    [created_on]               DATETIME2 (7) NULL,
    [last_modified_by]         VARCHAR (50)  NULL,
    [last_modified_on]         DATETIME2 (7) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([wf_level_group_config_id]) REFERENCES [apc].[wf_level_group_configuration] ([id])
);

