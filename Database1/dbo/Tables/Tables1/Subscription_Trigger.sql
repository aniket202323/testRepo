CREATE TABLE [dbo].[Subscription_Trigger] (
    [Subscription_Trigger_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Column_Name]             VARCHAR (100) NOT NULL,
    [From_Value]              VARCHAR (25)  NULL,
    [Key_Id]                  INT           NULL,
    [Subscription_Id]         INT           NOT NULL,
    [Table_Id]                INT           NOT NULL,
    [To_Value]                VARCHAR (25)  NULL,
    CONSTRAINT [SubscriptionTrigger_PK_SubscriptionTriggerId] PRIMARY KEY NONCLUSTERED ([Subscription_Trigger_Id] ASC),
    CONSTRAINT [SubscriptionTrigger_FK_SubscriptionId] FOREIGN KEY ([Subscription_Id]) REFERENCES [dbo].[Subscription] ([Subscription_Id]),
    CONSTRAINT [SubscriptionTrigger_FK_TableId] FOREIGN KEY ([Table_Id]) REFERENCES [dbo].[Tables] ([TableId])
);


GO
CREATE CLUSTERED INDEX [SubscriptionTrigger_IDX_SubscriptionIdKeyIdTableId]
    ON [dbo].[Subscription_Trigger]([Subscription_Id] ASC, [Key_Id] ASC, [Table_Id] ASC);

