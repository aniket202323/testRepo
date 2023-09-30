CREATE TABLE [dbo].[Customer] (
    [Customer_Id]        INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Address_1]          VARCHAR (255) NULL,
    [Address_2]          VARCHAR (255) NULL,
    [Address_3]          VARCHAR (255) NULL,
    [Address_4]          VARCHAR (255) NULL,
    [City]               VARCHAR (50)  NULL,
    [City_State_Zip]     VARCHAR (100) NULL,
    [Consignee_Code]     VARCHAR (50)  NULL,
    [Consignee_Name]     VARCHAR (100) NULL,
    [Contact_Name]       VARCHAR (100) NULL,
    [Contact_Phone]      VARCHAR (50)  NULL,
    [Country]            VARCHAR (50)  NULL,
    [County]             VARCHAR (50)  NULL,
    [Customer_Code]      VARCHAR (50)  NOT NULL,
    [Customer_General_1] VARCHAR (25)  NULL,
    [Customer_General_2] VARCHAR (25)  NULL,
    [Customer_General_3] VARCHAR (25)  NULL,
    [Customer_General_4] VARCHAR (25)  NULL,
    [Customer_General_5] VARCHAR (25)  NULL,
    [Customer_Name]      VARCHAR (100) NULL,
    [Customer_Type]      INT           NOT NULL,
    [Extended_Info]      VARCHAR (255) NULL,
    [Is_Active]          BIT           NOT NULL,
    [State]              VARCHAR (50)  NULL,
    [ZIP]                VARCHAR (25)  NULL,
    CONSTRAINT [Customer_PK_CustomerId] PRIMARY KEY CLUSTERED ([Customer_Id] ASC),
    CONSTRAINT [customer_IX_UC_CustomerCode] UNIQUE NONCLUSTERED ([Customer_Code] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Customer_IDX_ConCode]
    ON [dbo].[Customer]([Consignee_Code] ASC);


GO
CREATE TRIGGER [dbo].[Customer_TableFieldValue_Del]
 ON  [dbo].[Customer]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Customer_Id
 WHERE tfv.TableId = 50
