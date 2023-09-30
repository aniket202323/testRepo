CREATE TABLE [security].[Permission_Group_Details] (
    [id]                  INT IDENTITY (1, 1) NOT NULL,
    [permission_group_id] INT NOT NULL,
    [permission_id]       INT NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([permission_group_id]) REFERENCES [security].[Permissions_Grouping] ([id]),
    FOREIGN KEY ([permission_id]) REFERENCES [security].[Permissions] ([id])
);

