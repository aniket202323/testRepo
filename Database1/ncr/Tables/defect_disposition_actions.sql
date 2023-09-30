CREATE TABLE [ncr].[defect_disposition_actions] (
    [defect_id]              BIGINT NULL,
    [disposition_actions_id] BIGINT NULL,
    CONSTRAINT [FK__defect_di__defec__4BAC3F29] FOREIGN KEY ([defect_id]) REFERENCES [ncr].[defect] ([id]),
    CONSTRAINT [FK__defect_di__dispo__4CA06362] FOREIGN KEY ([disposition_actions_id]) REFERENCES [ncr].[disposition_action] ([id])
);

