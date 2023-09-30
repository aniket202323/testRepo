CREATE TABLE [apc].[wf_configuration] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]       VARCHAR (50)  NULL,
    [created_on]       DATETIME2 (7) NULL,
    [last_modified_by] VARCHAR (50)  NULL,
    [last_modified_on] DATETIME2 (7) NULL,
    [equipement_id]    BIGINT        NULL,
    [is_active]        BIT           NULL,
    [is_deleted]       BIT           NULL,
    [line_id]          BIGINT        NULL,
    [name]             VARCHAR (255) NULL,
    [wf_event_id]      INT           NULL,
    [initial_id]       INT           NULL,
    [revision]         INT           NULL,
    [co_owner]         VARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([wf_event_id]) REFERENCES [apc].[wf_event] ([id])
);

