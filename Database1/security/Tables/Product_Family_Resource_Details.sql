CREATE TABLE [security].[Product_Family_Resource_Details] (
    [assignment_id]     INT NULL,
    [product_family_id] INT NULL,
    FOREIGN KEY ([assignment_id]) REFERENCES [security].[Assignments] ([id]) ON DELETE CASCADE,
    FOREIGN KEY ([product_family_id]) REFERENCES [dbo].[Product_Family] ([Product_Family_Id]) ON DELETE CASCADE
);

