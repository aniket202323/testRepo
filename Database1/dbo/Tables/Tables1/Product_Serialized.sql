CREATE TABLE [dbo].[Product_Serialized] (
    [product_id]   INT NULL,
    [isSerialized] BIT NOT NULL,
    CONSTRAINT [FK__Product_S__produ__5C043931] FOREIGN KEY ([product_id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]) ON DELETE CASCADE
);

