CREATE TABLE [dbo].[process_order_custom_property_value] (
    [Process_Order_Id]       BIGINT           NOT NULL,
    [Property_definition_id] UNIQUEIDENTIFIER NOT NULL,
    [Value]                  NVARCHAR (MAX)   NULL
);

