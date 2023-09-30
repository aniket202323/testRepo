CREATE TABLE [dbo].[Customer_Order_Line_Specs] (
    [Order_Spec_Id]  INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Data_Type_Id]   INT           NOT NULL,
    [Is_Active]      BIT           CONSTRAINT [DF_Customer_Order_Line_Specs_Is_Active] DEFAULT ((1)) NOT NULL,
    [L_Limit]        VARCHAR (25)  NULL,
    [Order_Line_Id]  INT           NOT NULL,
    [Spec_Desc]      VARCHAR (100) NOT NULL,
    [Spec_Precision] INT           NULL,
    [Target]         VARCHAR (25)  NULL,
    [U_Limit]        VARCHAR (25)  NULL,
    CONSTRAINT [Customer_OSpecs_PK_OrderSpecId] PRIMARY KEY CLUSTERED ([Order_Spec_Id] ASC),
    CONSTRAINT [Customer_OSpecs_FK_OrderLineId] FOREIGN KEY ([Order_Line_Id]) REFERENCES [dbo].[Customer_Order_Line_Items] ([Order_Line_Id]),
    CONSTRAINT [Customer_OSpecs_UC_SpecDesc] UNIQUE NONCLUSTERED ([Order_Line_Id] ASC, [Spec_Desc] ASC)
);

