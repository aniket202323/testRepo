CREATE TABLE [dbo].[BF_MessageQueue] (
    [Instance_Id]   INT            NOT NULL,
    [Message_Text]  VARCHAR (7000) NULL,
    [Message_Topic] VARCHAR (100)  NULL,
    [Queue_Id]      INT            NOT NULL,
    [Sequence]      BIGINT         NOT NULL,
    [Service_Id]    INT            NOT NULL,
    CONSTRAINT [BF_MessageQueuee_PK_ServiceInstanceQueueSequence] PRIMARY KEY CLUSTERED ([Service_Id] ASC, [Instance_Id] ASC, [Queue_Id] ASC, [Sequence] ASC),
    CONSTRAINT [BFMessageQueue_FK_ServiceId] FOREIGN KEY ([Service_Id]) REFERENCES [dbo].[BF_Service] ([Service_Id])
);

