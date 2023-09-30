CREATE TABLE [pds].[property_category] (
    [id]               UNIQUEIDENTIFIER NOT NULL,
    [name]             VARCHAR (100)    NOT NULL,
    [version]          INT              NULL,
    [created_by]       VARCHAR (50)     NULL,
    [created_on]       DATETIME2 (7)    NULL,
    [last_modified_by] VARCHAR (50)     NULL,
    [last_modified_on] DATETIME2 (7)    NULL,
    [deleted]          BIT              DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

