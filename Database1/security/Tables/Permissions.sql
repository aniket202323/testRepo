CREATE TABLE [security].[Permissions] (
    [id]                INT            IDENTITY (1, 1) NOT NULL,
    [name]              NVARCHAR (500) NOT NULL,
    [description]       NVARCHAR (500) NULL,
    [scope]             NVARCHAR (255) NOT NULL,
    [created_by]        NVARCHAR (255) NULL,
    [created_date]      DATETIME2 (7)  NULL,
    [modified_by]       NVARCHAR (255) NULL,
    [modified_date]     DATETIME2 (7)  NULL,
    [is_app_permission] BIT            DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

