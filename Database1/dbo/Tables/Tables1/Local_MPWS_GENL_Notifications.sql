CREATE TABLE [dbo].[Local_MPWS_GENL_Notifications] (
    [Notification_Id]      INT           IDENTITY (1, 1) NOT NULL,
    [NotificationArea]     VARCHAR (50)  NOT NULL,
    [NotificationDesc]     VARCHAR (255) NOT NULL,
    [NotificationTime]     DATETIME      NOT NULL,
    [NotificationType]     VARCHAR (50)  NOT NULL,
    [AcknowledgedTime]     DATETIME      NULL,
    [AcknowledgedByUserId] INT           NULL,
    CONSTRAINT [PK_Local_MPWS_GENL_Notifications] PRIMARY KEY CLUSTERED ([Notification_Id] ASC)
);

