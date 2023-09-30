CREATE TABLE [dbo].[Customer_Orders] (
    [Order_Id]               INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Actual_Mfg_Date]        DATETIME      NULL,
    [Actual_Ship_Date]       DATETIME      NULL,
    [Comment_Id]             INT           NULL,
    [Consignee_Id]           INT           NULL,
    [Corporate_Order_Number] VARCHAR (50)  NULL,
    [Customer_Id]            INT           NOT NULL,
    [Customer_Order_Number]  VARCHAR (50)  NOT NULL,
    [Entered_By]             INT           NOT NULL,
    [Entered_Date]           DATETIME      NOT NULL,
    [Extended_Info]          VARCHAR (255) NULL,
    [Forecast_Mfg_Date]      DATETIME      NULL,
    [Forecast_Ship_Date]     DATETIME      NULL,
    [Is_Active]              BIT           CONSTRAINT [DF_Customer_Orders_Is_Active] DEFAULT ((1)) NOT NULL,
    [Order_General_1]        VARCHAR (25)  NULL,
    [Order_General_2]        VARCHAR (25)  NULL,
    [Order_General_3]        VARCHAR (25)  NULL,
    [Order_General_4]        VARCHAR (25)  NULL,
    [Order_General_5]        VARCHAR (25)  NULL,
    [Order_Instructions]     VARCHAR (255) NULL,
    [Order_Status]           VARCHAR (10)  NOT NULL,
    [Order_Type]             VARCHAR (10)  NOT NULL,
    [Plant_Order_Number]     VARCHAR (50)  NOT NULL,
    [Schedule_Block_Number]  VARCHAR (50)  NULL,
    [Total_Line_Items]       INT           NULL,
    CONSTRAINT [Customer_Orders_PK_OrderId] PRIMARY KEY CLUSTERED ([Order_Id] ASC),
    CONSTRAINT [Customer_Orders_FK_ConsigneeId] FOREIGN KEY ([Consignee_Id]) REFERENCES [dbo].[Customer] ([Customer_Id]),
    CONSTRAINT [Customer_Orders_FK_CustomerId] FOREIGN KEY ([Customer_Id]) REFERENCES [dbo].[Customer] ([Customer_Id]),
    CONSTRAINT [Customer_Orders_FK_EnteredBy] FOREIGN KEY ([Entered_By]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE NONCLUSTERED INDEX [CustOrder_IDX_PlantOrder]
    ON [dbo].[Customer_Orders]([Plant_Order_Number] ASC);


GO
CREATE NONCLUSTERED INDEX [CustOrder_IDX_CustEnteredDate]
    ON [dbo].[Customer_Orders]([Customer_Id] ASC, [Entered_Date] ASC);


GO
CREATE NONCLUSTERED INDEX [CustOrder_IDX_CustOrder]
    ON [dbo].[Customer_Orders]([Customer_Order_Number] ASC);


GO
CREATE NONCLUSTERED INDEX [CustOrder_IDX_CustCustOrder]
    ON [dbo].[Customer_Orders]([Customer_Id] ASC, [Customer_Order_Number] ASC);


GO
CREATE NONCLUSTERED INDEX [CustOrder_IDX_CustPlantOrder]
    ON [dbo].[Customer_Orders]([Customer_Id] ASC, [Plant_Order_Number] ASC);


GO
CREATE TRIGGER [dbo].[Customer_Orders_TableFieldValue_Del]
 ON  [dbo].[Customer_Orders]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Order_Id
 WHERE tfv.TableId = 45
