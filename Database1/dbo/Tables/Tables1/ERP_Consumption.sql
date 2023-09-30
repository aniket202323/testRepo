CREATE TABLE [dbo].[ERP_Consumption] (
    [ERP_Consumption_Id] INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Component_Id]       INT      NOT NULL,
    [Confirmed]          BIT      CONSTRAINT [ERPConsumption_DF_Confirmed] DEFAULT ((0)) NOT NULL,
    [Event_Id]           INT      NOT NULL,
    [Modified_On]        DATETIME NOT NULL,
    [PP_Id]              INT      NOT NULL,
    [Prod_Id]            INT      NOT NULL,
    [Quantity]           REAL     CONSTRAINT [ERPConsumption_DF_Quantity] DEFAULT ((0)) NOT NULL,
    [Source_Event_Id]    INT      NOT NULL,
    [Subscription_Id]    INT      NOT NULL,
    [TimeStamp]          DATETIME CONSTRAINT [ERPConsumption_DF_TimeStamp] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [ERPConsumption_PK_ERPConsumptionId] PRIMARY KEY NONCLUSTERED ([ERP_Consumption_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [CIX_ERP_Consumption]
    ON [dbo].[ERP_Consumption]([Subscription_Id] ASC, [PP_Id] ASC, [Event_Id] ASC, [Component_Id] ASC);

