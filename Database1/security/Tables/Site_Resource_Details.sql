CREATE TABLE [security].[Site_Resource_Details] (
    [assignment_id] INT NULL,
    [site_id]       INT NULL,
    FOREIGN KEY ([assignment_id]) REFERENCES [security].[Assignments] ([id]) ON DELETE CASCADE
);

