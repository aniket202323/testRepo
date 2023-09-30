CREATE TABLE [security].[Role_Details] (
    [id]            INT IDENTITY (1, 1) NOT NULL,
    [permission_id] INT NOT NULL,
    [role_id]       INT NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([permission_id]) REFERENCES [security].[Permissions] ([id]),
    FOREIGN KEY ([role_id]) REFERENCES [security].[Role_Base] ([id])
);

