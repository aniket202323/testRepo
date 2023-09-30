CREATE TABLE [dbo].[ERP_Production] (
    [ERP_Production_Id] INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Confirmed]         BIT      CONSTRAINT [ERPProduction_DF_Confirmed] DEFAULT ((0)) NOT NULL,
    [Key_Id]            INT      NOT NULL,
    [Modified_On]       DATETIME NOT NULL,
    [PP_Id]             INT      NOT NULL,
    [Prod_Id]           INT      NOT NULL,
    [Production_Type]   SMALLINT CONSTRAINT [ERPProduction_DF_ProductionType] DEFAULT ((0)) NOT NULL,
    [Quantity]          REAL     CONSTRAINT [ERPProduction_DF_Quantity] DEFAULT ((0)) NOT NULL,
    [Subscription_Id]   INT      NOT NULL,
    [TimeStamp]         DATETIME CONSTRAINT [ERPProduction_DF_TimeStamp] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [ERPProduction_PK_ERPProductionId] PRIMARY KEY NONCLUSTERED ([ERP_Production_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [CIX_ERP_Production]
    ON [dbo].[ERP_Production]([Subscription_Id] ASC, [PP_Id] ASC, [Production_Type] ASC, [Key_Id] ASC);

