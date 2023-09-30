CREATE TABLE [ncr].[context_type_disposition_type] (
    [context_type_id]     BIGINT NULL,
    [disposition_type_id] BIGINT NULL,
    FOREIGN KEY ([context_type_id]) REFERENCES [ncr].[context_type] ([id]),
    FOREIGN KEY ([disposition_type_id]) REFERENCES [ncr].[disposition_type] ([id]),
    CONSTRAINT [UK_context_type_id_disposition_type_id] UNIQUE NONCLUSTERED ([context_type_id] ASC, [disposition_type_id] ASC)
);

