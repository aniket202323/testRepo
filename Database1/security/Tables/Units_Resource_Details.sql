CREATE TABLE [security].[Units_Resource_Details] (
    [assignment_id] INT NULL,
    [units_id]      INT NULL,
    FOREIGN KEY ([assignment_id]) REFERENCES [security].[Assignments] ([id]) ON DELETE CASCADE,
    FOREIGN KEY ([units_id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]) ON DELETE CASCADE
);

