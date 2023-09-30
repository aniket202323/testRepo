CREATE TABLE [security].[Department_Resource_Details] (
    [assignment_id] INT NULL,
    [department_id] INT NULL,
    FOREIGN KEY ([assignment_id]) REFERENCES [security].[Assignments] ([id]) ON DELETE CASCADE,
    FOREIGN KEY ([department_id]) REFERENCES [dbo].[Departments_Base] ([Dept_Id]) ON DELETE CASCADE
);

