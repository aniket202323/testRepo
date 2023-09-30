CREATE TABLE [security].[Product_Resource_Details] (
    [assignment_id] INT NULL,
    [product_id]    INT NULL,
    FOREIGN KEY ([assignment_id]) REFERENCES [security].[Assignments] ([id]) ON DELETE CASCADE,
    FOREIGN KEY ([product_id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]) ON DELETE CASCADE
);

