CREATE TABLE [dbo].[Product_Characteristic_Defaults] (
    [Char_Id] INT NOT NULL,
    [Prod_Id] INT NOT NULL,
    [Prop_Id] INT NOT NULL,
    CONSTRAINT [FK_Product_Characteristic_Defaults_Characteristics] FOREIGN KEY ([Char_Id]) REFERENCES [dbo].[Characteristics] ([Char_Id]),
    CONSTRAINT [FK_Product_Characteristic_Defaults_Product_Properties] FOREIGN KEY ([Prop_Id]) REFERENCES [dbo].[Product_Properties] ([Prop_Id]),
    CONSTRAINT [FK_Product_Characteristic_Defaults_Products] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [IX_Product_Characteristic_Defaults] UNIQUE NONCLUSTERED ([Prod_Id] ASC, [Prop_Id] ASC)
);

