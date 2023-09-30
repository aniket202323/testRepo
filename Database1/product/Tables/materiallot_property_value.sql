CREATE TABLE [product].[materiallot_property_value] (
    [id]                     BIGINT           IDENTITY (1, 1) NOT NULL,
    [Material_Lot_id]        BIGINT           NULL,
    [Property_definition_id] UNIQUEIDENTIFIER NULL,
    [Value]                  NVARCHAR (MAX)   NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [U_MTRL_VL_PROPERTY_DEFINITION_ID] UNIQUE NONCLUSTERED ([Property_definition_id] ASC, [Material_Lot_id] ASC)
);

