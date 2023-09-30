CREATE TABLE [ncr].[disposition_action_template] (
    [id]                  BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]          VARCHAR (255) NULL,
    [created_on]          DATETIME2 (7) NULL,
    [last_modified_by]    VARCHAR (255) NULL,
    [last_modified_on]    DATETIME2 (7) NULL,
    [version]             INT           NULL,
    [template_id]         VARCHAR (255) NULL,
    [disposition_type_id] BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__dispositi__dispo__5535A963] FOREIGN KEY ([disposition_type_id]) REFERENCES [ncr].[disposition_type] ([id])
);

