CREATE TABLE [apc].[wf_activties_association] (
    [id]                          INT           IDENTITY (1, 1) NOT NULL,
    [activty_id]                  BIGINT        NULL,
    [event_number]                VARCHAR (255) NULL,
    [apc_sheet_name]              VARCHAR (255) NULL,
    [created_on]                  DATETIME2 (7) NULL,
    [wf_level_group_execution_id] BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

