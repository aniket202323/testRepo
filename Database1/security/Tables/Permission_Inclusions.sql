CREATE TABLE [security].[Permission_Inclusions] (
    [app_permission_id] INT NOT NULL,
    [permission_id]     INT NOT NULL,
    FOREIGN KEY ([app_permission_id]) REFERENCES [security].[Permissions] ([id]),
    FOREIGN KEY ([permission_id]) REFERENCES [security].[Permissions] ([id])
);

