CREATE TABLE [dbo].[Customer_Order_Line_Details] (
    [Order_Line_Detail_Id] INT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Is_Active]            BIT        CONSTRAINT [DF_Customer_Order_Line_Details_Is_Active] DEFAULT ((1)) NOT NULL,
    [Line_Detail_Number]   INT        NOT NULL,
    [Order_Line_Id]        INT        NOT NULL,
    [Ordered_Quantity]     FLOAT (53) NULL,
    [Promised_Date]        DATETIME   NULL,
    [Required_Date]        DATETIME   NULL,
    CONSTRAINT [Customer_LDetail_PK_OrderLineDetailId] PRIMARY KEY CLUSTERED ([Order_Line_Detail_Id] ASC),
    CONSTRAINT [Customer_LIDetails_FK_OrderId] FOREIGN KEY ([Order_Line_Id]) REFERENCES [dbo].[Customer_Order_Line_Items] ([Order_Line_Id])
);


GO
CREATE NONCLUSTERED INDEX [CustOrderLineDet_IDX_OrderLine]
    ON [dbo].[Customer_Order_Line_Details]([Order_Line_Id] ASC);


GO
CREATE TRIGGER [dbo].[Customer_Order_Line_Details_TableFieldValue_Del]
 ON  [dbo].[Customer_Order_Line_Details]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Order_Line_Detail_Id
 WHERE tfv.TableId = 47
