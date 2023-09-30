CREATE TABLE [apc].[wf_level_status] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]       VARCHAR (50)  NULL,
    [created_on]       DATETIME2 (7) NULL,
    [last_modified_by] VARCHAR (50)  NULL,
    [last_modified_on] DATETIME2 (7) NULL,
    [level_id]         INT           NOT NULL,
    [status_id]        INT           NOT NULL,
    [wf_execution_id]  BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([wf_execution_id]) REFERENCES [apc].[wf_execution] ([id])
);

