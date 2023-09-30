CREATE TABLE [dbo].[Data_Source_XRef] (
    [DS_XRef_Id]      INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Actual_Id]       BIGINT        NULL,
    [Actual_Text]     VARCHAR (50)  NULL,
    [DS_Id]           INT           NOT NULL,
    [Foreign_Key]     VARCHAR (255) NULL,
    [Subscription_Id] INT           NULL,
    [Table_Id]        INT           NOT NULL,
    [XML_Header]      VARCHAR (255) NULL,
    CONSTRAINT [DSXRef_PK_DSXRefId] PRIMARY KEY NONCLUSTERED ([DS_XRef_Id] ASC),
    CONSTRAINT [DSXRef_FK_DataSource] FOREIGN KEY ([DS_Id]) REFERENCES [dbo].[Data_Source] ([DS_Id]),
    CONSTRAINT [DSXRef_FK_Subscription] FOREIGN KEY ([Subscription_Id]) REFERENCES [dbo].[Subscription] ([Subscription_Id]),
    CONSTRAINT [DSXRef_FK_Tables] FOREIGN KEY ([Table_Id]) REFERENCES [dbo].[Tables] ([TableId])
);


GO
CREATE CLUSTERED INDEX [DSXRef_IX_DSIdTableIdSubscriptionIdActualIdActualText]
    ON [dbo].[Data_Source_XRef]([DS_Id] ASC, [Table_Id] ASC, [Subscription_Id] ASC, [Actual_Id] ASC, [Actual_Text] ASC);


GO
CREATE NONCLUSTERED INDEX [DSXRef_IX_DSIdTableIdSubscriptionIdForeignKey]
    ON [dbo].[Data_Source_XRef]([DS_Id] ASC, [Table_Id] ASC, [Subscription_Id] ASC, [Foreign_Key] ASC);

