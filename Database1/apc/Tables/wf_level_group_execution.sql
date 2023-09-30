CREATE TABLE [apc].[wf_level_group_execution] (
    [id]                       BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]               VARCHAR (50)  NULL,
    [created_on]               DATETIME2 (7) NULL,
    [last_modified_by]         VARCHAR (50)  NULL,
    [last_modified_on]         DATETIME2 (7) NULL,
    [rejectionTag]             VARCHAR (255) NULL,
    [status_id]                INT           NOT NULL,
    [wf_execution_id]          BIGINT        NULL,
    [wf_level_group_config_id] BIGINT        NULL,
    [recieved_reverification]  BIT           NULL,
    [escalation_mail_flag]     BIT           NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([wf_execution_id]) REFERENCES [apc].[wf_execution] ([id]),
    FOREIGN KEY ([wf_level_group_config_id]) REFERENCES [apc].[wf_level_group_configuration] ([id])
);

