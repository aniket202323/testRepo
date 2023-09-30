CREATE TABLE [dbo].[Subscription_Group] (
    [Subscription_Group_Id]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Priority]                INT           NULL,
    [Stored_Procedure_Name]   VARCHAR (255) NULL,
    [Subscription_Group_Desc] VARCHAR (255) NOT NULL,
    CONSTRAINT [SubscriptionGroup_PK_SubscriptionGroupId] PRIMARY KEY NONCLUSTERED ([Subscription_Group_Id] ASC),
    CONSTRAINT [SubscriptionGroup_UC_SubscGroupDesc] UNIQUE NONCLUSTERED ([Subscription_Group_Desc] ASC)
);


GO
CREATE TRIGGER [dbo].[Subscription_Group_TableFieldValue_Del]
 ON  [dbo].[Subscription_Group]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Subscription_Group_Id
 WHERE tfv.TableId = 29
