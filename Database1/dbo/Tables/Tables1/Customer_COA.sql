CREATE TABLE [dbo].[Customer_COA] (
    [Customer_COA_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [COA_Id]          INT           NOT NULL,
    [Comment_Id]      INT           NULL,
    [Customer_Id]     INT           NOT NULL,
    [Report_Name]     VARCHAR (100) NULL,
    CONSTRAINT [Customer_COA_PK_CustCOAId] PRIMARY KEY CLUSTERED ([Customer_COA_Id] ASC),
    CONSTRAINT [Customer_COA_FK_COAId] FOREIGN KEY ([COA_Id]) REFERENCES [dbo].[COA] ([COA_Id]),
    CONSTRAINT [Customer_COA_FK_CustomerId] FOREIGN KEY ([Customer_Id]) REFERENCES [dbo].[Customer] ([Customer_Id])
);

