CREATE TABLE [ncr].[disposition_plan_history] (
    [id]                     BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]             VARCHAR (255) NULL,
    [created_on]             DATETIME2 (7) NULL,
    [last_modified_by]       VARCHAR (255) NULL,
    [last_modified_on]       DATETIME2 (7) NULL,
    [version]                INT           NULL,
    [column_updated_bitmask] VARCHAR (15)  NULL,
    [dbtt_id]                INT           NULL,
    [modified_on]            DATETIME2 (7) NULL,
    [name]                   VARCHAR (255) NULL,
    [requires_review]        BIT           NULL,
    [reviewed]               BIT           NULL,
    [reviewed_by]            VARCHAR (255) NULL,
    [reviewed_on]            DATETIME2 (7) NULL,
    [source]                 VARCHAR (255) NULL,
    [disposition_plan_id]    BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__dispositi__dispo__5629CD9C] FOREIGN KEY ([disposition_plan_id]) REFERENCES [ncr].[disposition_plan] ([id])
);

