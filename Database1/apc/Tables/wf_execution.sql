CREATE TABLE [apc].[wf_execution] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]       VARCHAR (50)  NULL,
    [created_on]       DATETIME2 (7) NULL,
    [last_modified_by] VARCHAR (50)  NULL,
    [last_modified_on] DATETIME2 (7) NULL,
    [current_level]    INT           NOT NULL,
    [deleted]          BIT           NOT NULL,
    [req_id]           VARCHAR (255) NOT NULL,
    [req_name]         VARCHAR (255) NOT NULL,
    [status_id]        INT           NOT NULL,
    [wf_config_id]     BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([wf_config_id]) REFERENCES [apc].[wf_configuration] ([id])
);

