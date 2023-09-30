CREATE TABLE [security].[Assignment_Group_Details] (
    [id]            INT            IDENTITY (1, 1) NOT NULL,
    [group_id]      NVARCHAR (500) NOT NULL,
    [assignment_id] INT            NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([assignment_id]) REFERENCES [security].[Assignments] ([id]) ON DELETE CASCADE
);

