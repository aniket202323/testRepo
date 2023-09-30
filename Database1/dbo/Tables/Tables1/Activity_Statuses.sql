CREATE TABLE [dbo].[Activity_Statuses] (
    [ActivityStatus_Id]   INT           IDENTITY (1, 1) NOT NULL,
    [ActivityStatus_Desc] VARCHAR (100) NULL,
    CONSTRAINT [ActivityStatus_PK_ActivityStatusId] PRIMARY KEY CLUSTERED ([ActivityStatus_Id] ASC)
);

