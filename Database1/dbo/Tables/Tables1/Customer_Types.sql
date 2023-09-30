CREATE TABLE [dbo].[Customer_Types] (
    [Customer_Type_Desc] VARCHAR (50) NOT NULL,
    [Customer_Type_Id]   TINYINT      NOT NULL,
    CONSTRAINT [Customer_Types_PK_Id] PRIMARY KEY CLUSTERED ([Customer_Type_Id] ASC),
    CONSTRAINT [Customer_Types_IX_Desc] UNIQUE NONCLUSTERED ([Customer_Type_Desc] ASC)
);

