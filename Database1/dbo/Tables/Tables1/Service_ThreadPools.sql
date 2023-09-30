CREATE TABLE [dbo].[Service_ThreadPools] (
    [Pool_Id]            INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Heartbeat_Interval] INT           NULL,
    [Is_Default]         BIT           NOT NULL,
    [Is_Message_Pool]    BIT           NOT NULL,
    [Pool_Desc]          VARCHAR (100) NULL,
    [Service_Id]         SMALLINT      NOT NULL,
    [Thread_Count]       INT           CONSTRAINT [DF__Service_T__Threa__448BD6FC] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [Service_ThreadPoolsPKPoolId] PRIMARY KEY NONCLUSTERED ([Pool_Id] ASC),
    CONSTRAINT [ThreadPoolCXSService_FK_ServiceId] FOREIGN KEY ([Service_Id]) REFERENCES [dbo].[CXS_Service] ([Service_Id])
);

