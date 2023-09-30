CREATE TABLE [dbo].[Subscription] (
    [Subscription_Id]       INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Is_Active]             TINYINT       CONSTRAINT [Subscription_DF_IsActive] DEFAULT ((1)) NULL,
    [Key_Id]                BIGINT        NULL,
    [Last_Processed_Date]   DATETIME      NOT NULL,
    [Subscription_Desc]     VARCHAR (255) NOT NULL,
    [Subscription_Group_Id] INT           NULL,
    [Table_Id]              INT           NULL,
    [Time_Trigger_Interval] INT           NULL,
    [Time_Trigger_Offset]   INT           NULL,
    CONSTRAINT [Subscription_PK_SubscriptionId] PRIMARY KEY NONCLUSTERED ([Subscription_Id] ASC),
    CONSTRAINT [Subscription_FK_SubscriptionGroupId] FOREIGN KEY ([Subscription_Group_Id]) REFERENCES [dbo].[Subscription_Group] ([Subscription_Group_Id]),
    CONSTRAINT [Subscription_FK_TableId] FOREIGN KEY ([Table_Id]) REFERENCES [dbo].[Tables] ([TableId]),
    CONSTRAINT [Subscription_UC_SubscDesc] UNIQUE NONCLUSTERED ([Subscription_Desc] ASC)
);


GO
CREATE TRIGGER [dbo].[Subscription_TableFieldValue_Del]
 ON  [dbo].[Subscription]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Subscription_Id
 WHERE tfv.TableId = 27
