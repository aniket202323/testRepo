CREATE TABLE [security].[Privilege_Sets] (
    [id]          INT            NOT NULL,
    [displayname] NVARCHAR (255) NULL,
    [scope]       NVARCHAR (255) NULL,
    [description] NVARCHAR (255) NULL,
    [icon]        NVARCHAR (255) NULL,
    [category]    NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

