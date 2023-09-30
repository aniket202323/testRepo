CREATE TABLE [dbo].[Shipment_Line_Items] (
    [Shipment_Item_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Actual_Quantity]  FLOAT (53)    NULL,
    [Comment_Id]       INT           NULL,
    [Is_Active]        BIT           CONSTRAINT [DF_Shipment_Line_Items_Is_Active] DEFAULT ((1)) NOT NULL,
    [Order_Id]         INT           NULL,
    [Order_Line_Id]    INT           NULL,
    [Shipment_Id]      INT           NOT NULL,
    [User_General_1]   VARCHAR (255) NULL,
    [User_General_2]   VARCHAR (255) NULL,
    [User_General_3]   VARCHAR (255) NULL,
    [User_General_4]   VARCHAR (255) NULL,
    [User_General_5]   VARCHAR (255) NULL,
    CONSTRAINT [Shipment_LItems_PK_ShipItemId] PRIMARY KEY CLUSTERED ([Shipment_Item_Id] ASC),
    CONSTRAINT [Shipment_LItems_FK_OrderId] FOREIGN KEY ([Order_Id]) REFERENCES [dbo].[Customer_Orders] ([Order_Id]),
    CONSTRAINT [Shipment_LItems_FK_OrderLId] FOREIGN KEY ([Order_Line_Id]) REFERENCES [dbo].[Customer_Order_Line_Items] ([Order_Line_Id]),
    CONSTRAINT [Shipment_LItems_FK_ShipmentId] FOREIGN KEY ([Shipment_Id]) REFERENCES [dbo].[Shipment] ([Shipment_Id])
);


GO
CREATE NONCLUSTERED INDEX [Shipment_LItems_IDX_OrderLine]
    ON [dbo].[Shipment_Line_Items]([Order_Line_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Shipment_LItems_IDX_Shipment]
    ON [dbo].[Shipment_Line_Items]([Shipment_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Shipment_LItems_IDX_Order]
    ON [dbo].[Shipment_Line_Items]([Order_Id] ASC);


GO
CREATE TRIGGER [dbo].[Shipment_Line_Items_TableFieldValue_Del]
 ON  [dbo].[Shipment_Line_Items]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Shipment_Item_Id
 WHERE tfv.TableId = 49

GO
CREATE TRIGGER dbo.Shipment_Line_Items_Del ON dbo.Shipment_Line_Items
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Shipment_Line_Items_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Shipment_Line_Items_Del_Cursor 
--
--
Fetch_Shipment_Line_Items_Del:
FETCH NEXT FROM Shipment_Line_Items_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Shipment_Line_Items_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Shipment_Line_Items_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Shipment_Line_Items_Del_Cursor 
