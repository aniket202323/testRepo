CREATE TABLE [pds].[property_data_type] (
    [id]             INT           IDENTITY (1, 1) NOT NULL,
    [name]           VARCHAR (255) NULL,
    [data_type_desc] VARCHAR (255) NULL,
    [use_precision]  INT           NOT NULL,
    [user_defined]   INT           NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [UK_property_data_type_name] UNIQUE NONCLUSTERED ([name] ASC)
);

