CREATE TABLE [dbo].[Local_PG_CL_Alarms_Notifications] (
    [Notification_Id]        INT           IDENTITY (1, 1) NOT NULL,
    [Var_Id]                 INT           NOT NULL,
    [Test_Id]                BIGINT        NOT NULL,
    [Notification]           VARCHAR (255) NULL,
    [Last_ModifiedTimeStamp] DATETIME      NULL,
    CONSTRAINT [PK_Local_PG_CL_Alarms_Notifications] PRIMARY KEY NONCLUSTERED ([Notification_Id] ASC)
);

