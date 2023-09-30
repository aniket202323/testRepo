CREATE TABLE [pds].[property_definition] (
    [id]                    UNIQUEIDENTIFIER NOT NULL,
    [name]                  VARCHAR (100)    NOT NULL,
    [display_name]          VARCHAR (100)    NULL,
    [default_value]         VARCHAR (1000)   NULL,
    [initial_id]            UNIQUEIDENTIFIER NULL,
    [required]              BIT              NULL,
    [uom]                   INT              NULL,
    [property_data_type_id] INT              NULL,
    [property_group_id]     UNIQUEIDENTIFIER NULL,
    [version]               INT              NULL,
    [deleted]               BIT              NULL,
    [created_by]            VARCHAR (50)     NULL,
    [created_on]            DATETIME2 (7)    NULL,
    [last_modified_by]      VARCHAR (50)     NULL,
    [last_modified_on]      DATETIME2 (7)    NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [Fk_Prop_def_PropDataTypeId] FOREIGN KEY ([property_data_type_id]) REFERENCES [pds].[property_data_type] ([id]),
    CONSTRAINT [FK_Prop_def_PropgrpId] FOREIGN KEY ([property_group_id]) REFERENCES [pds].[property_group] ([id])
);

