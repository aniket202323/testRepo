CREATE TABLE [dbo].[Local_E2P_Received_FPP_Statuses] (
    [StatusId]    INT          IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (50) NOT NULL,
    CONSTRAINT [LocalE2PReceivedFPPStatuses_PK_StatusId] PRIMARY KEY CLUSTERED ([StatusId] ASC)
);

