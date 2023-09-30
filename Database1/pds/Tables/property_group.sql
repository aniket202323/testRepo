CREATE TABLE [pds].[property_group] (
    [id]                   UNIQUEIDENTIFIER NOT NULL,
    [name]                 VARCHAR (100)    NOT NULL,
    [alias_name]           VARCHAR (100)    NULL,
    [description]          VARCHAR (1000)   NULL,
    [initial_id]           UNIQUEIDENTIFIER NULL,
    [property_category_id] UNIQUEIDENTIFIER NULL,
    [version]              INT              NULL,
    [deleted]              BIT              NOT NULL,
    [created_by]           VARCHAR (50)     NULL,
    [created_on]           DATETIME2 (7)    NULL,
    [last_modified_by]     VARCHAR (50)     NULL,
    [last_modified_on]     DATETIME2 (7)    NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_Prop_Grp_PropCatId] FOREIGN KEY ([property_category_id]) REFERENCES [pds].[property_category] ([id])
);

