CREATE TABLE [product].[product_property_value] (
    [id]                     BIGINT           IDENTITY (1, 1) NOT NULL,
    [Product_id]             BIGINT           NULL,
    [Property_definition_id] UNIQUEIDENTIFIER NULL,
    [Value]                  NVARCHAR (MAX)   NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [U_PRDC_VL_PROPERTY_DEFINITION_ID] UNIQUE NONCLUSTERED ([Property_definition_id] ASC, [Product_id] ASC)
);

