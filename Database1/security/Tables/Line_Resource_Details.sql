CREATE TABLE [security].[Line_Resource_Details] (
    [assignment_id] INT NULL,
    [line_id]       INT NULL,
    FOREIGN KEY ([assignment_id]) REFERENCES [security].[Assignments] ([id]) ON DELETE CASCADE,
    FOREIGN KEY ([line_id]) REFERENCES [dbo].[Prod_Lines_Base] ([PL_Id]) ON DELETE CASCADE
);

