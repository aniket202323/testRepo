CREATE TABLE [dbo].[Customer_Order_Line_Items] (
    [Order_Line_Id]         INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [COA_Date]              DATETIME      NULL,
    [Comment_Id]            INT           NULL,
    [Complete_Date]         DATETIME      NULL,
    [Consignee_Id]          INT           NULL,
    [Dimension_A]           REAL          NULL,
    [Dimension_A_Tolerance] REAL          NULL,
    [Dimension_X]           REAL          NULL,
    [Dimension_X_Tolerance] REAL          NULL,
    [Dimension_Y]           REAL          NULL,
    [Dimension_Y_Tolerance] REAL          NULL,
    [Dimension_Z]           REAL          NULL,
    [Dimension_Z_Tolerance] REAL          NULL,
    [EndUser_Id]            INT           NULL,
    [Extended_Info]         VARCHAR (255) NULL,
    [Is_Active]             BIT           CONSTRAINT [DF_Customer_Order_Line_Items_Is_Active] DEFAULT ((1)) NOT NULL,
    [Line_Item_Number]      INT           NOT NULL,
    [Order_Id]              INT           NOT NULL,
    [Order_Line_General_1]  VARCHAR (255) NULL,
    [Order_Line_General_2]  VARCHAR (255) NULL,
    [Order_Line_General_3]  VARCHAR (255) NULL,
    [Order_Line_General_4]  VARCHAR (255) NULL,
    [Order_Line_General_5]  VARCHAR (255) NULL,
    [Ordered_Quantity]      FLOAT (53)    NULL,
    [Ordered_UOM]           VARCHAR (10)  NULL,
    [Prod_Id]               INT           NOT NULL,
    [ShipTo_Id]             INT           NULL,
    CONSTRAINT [Customer_LItems_PK_OrderLineId] PRIMARY KEY CLUSTERED ([Order_Line_Id] ASC),
    CONSTRAINT [Customer_LItems_FK_ConsigneeId] FOREIGN KEY ([Consignee_Id]) REFERENCES [dbo].[Customer] ([Customer_Id]),
    CONSTRAINT [Customer_LItems_FK_OrderId] FOREIGN KEY ([Order_Id]) REFERENCES [dbo].[Customer_Orders] ([Order_Id]),
    CONSTRAINT [Customer_LItems_FK_Prod_Id] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id])
);


GO
CREATE NONCLUSTERED INDEX [CustOrderLine_IDX_Order]
    ON [dbo].[Customer_Order_Line_Items]([Order_Id] ASC);


GO
CREATE TRIGGER [dbo].[Customer_Order_Line_Items_TableFieldValue_Del]
 ON  [dbo].[Customer_Order_Line_Items]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Order_Line_Id
 WHERE tfv.TableId = 46
