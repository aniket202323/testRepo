CREATE TABLE [ncr].[disposition_action_property_value_history] (
    [id]                                   BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]                           VARCHAR (255) NULL,
    [created_on]                           DATETIME2 (7) NULL,
    [last_modified_by]                     VARCHAR (255) NULL,
    [last_modified_on]                     DATETIME2 (7) NULL,
    [version]                              INT           NULL,
    [property_definition_id]               VARCHAR (255) NULL,
    [value]                                VARCHAR (255) NULL,
    [column_updated_bitmask]               VARCHAR (15)  NULL,
    [dbtt_id]                              INT           NULL,
    [modified_on]                          DATETIME2 (7) NULL,
    [disposition_action_history_id]        BIGINT        NULL,
    [origin_id]                            BIGINT        NULL,
    [disposition_action_property_value_id] BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__dispositi__dispo__04E4BC85] FOREIGN KEY ([disposition_action_property_value_id]) REFERENCES [ncr].[disposition_action_property_value] ([id])
);

