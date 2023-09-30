CREATE TABLE [dbo].[Bus_Subscriptions] (
    [Description] VARCHAR (100) NULL,
    [Message_Id]  INT           NOT NULL,
    CONSTRAINT [BusSubscriptions_PK_MessageId] PRIMARY KEY CLUSTERED ([Message_Id] ASC),
    CONSTRAINT [BusSubscriptions_FK_MessageId] FOREIGN KEY ([Message_Id]) REFERENCES [dbo].[Message_Types] ([Message_Id])
);

