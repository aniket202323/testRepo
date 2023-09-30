CREATE TABLE [dbo].[Local_PE_LogTypes] (
    [LogType_Id]          INT            IDENTITY (1, 1) NOT NULL,
    [LogType_Desc]        NVARCHAR (MAX) NOT NULL,
    [ShowInPEMobile]      BIT            NOT NULL,
    [MonitoredByHelpDesk] BIT            NOT NULL,
    [IsNotification]      BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Local_PE_LogTypes] PRIMARY KEY CLUSTERED ([LogType_Id] ASC)
);

