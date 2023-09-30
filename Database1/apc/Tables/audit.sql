CREATE TABLE [apc].[audit] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]       VARCHAR (50)  NULL,
    [created_on]       DATETIME2 (7) NULL,
    [last_modified_by] VARCHAR (50)  NULL,
    [last_modified_on] DATETIME2 (7) NULL,
    [data]             VARCHAR (255) NULL,
    [entity]           VARCHAR (255) NULL,
    [reason]           VARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

