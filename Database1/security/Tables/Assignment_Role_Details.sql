CREATE TABLE [security].[Assignment_Role_Details] (
    [assignment_id] INT NULL,
    [role_id]       INT NULL,
    FOREIGN KEY ([assignment_id]) REFERENCES [security].[Assignments] ([id]) ON DELETE CASCADE,
    FOREIGN KEY ([role_id]) REFERENCES [security].[Role_Base] ([id]) ON DELETE CASCADE
);

