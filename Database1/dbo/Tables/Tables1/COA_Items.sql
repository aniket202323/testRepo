CREATE TABLE [dbo].[COA_Items] (
    [COA_Item_Id]      INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Calculation_Type] TINYINT      NOT NULL,
    [COA_Id]           INT          NOT NULL,
    [Comment_Id]       INT          NULL,
    [Customer_Id]      INT          NOT NULL,
    [Options_1]        VARCHAR (25) NULL,
    [Options_2]        VARCHAR (25) NULL,
    [Options_3]        VARCHAR (25) NULL,
    [Options_4]        VARCHAR (25) NULL,
    [Options_5]        VARCHAR (25) NULL,
    [Prod_Id]          INT          NOT NULL,
    [Var_Id]           INT          NULL,
    CONSTRAINT [COA_Items_PK_COAItemId] PRIMARY KEY CLUSTERED ([COA_Item_Id] ASC),
    CONSTRAINT [COA_Items_FK_COAId] FOREIGN KEY ([COA_Id]) REFERENCES [dbo].[COA] ([COA_Id]),
    CONSTRAINT [COA_Items_FK_CustomerId] FOREIGN KEY ([Customer_Id]) REFERENCES [dbo].[Customer] ([Customer_Id]),
    CONSTRAINT [COA_Items_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [COA_Items_FK_VarId] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id])
);

