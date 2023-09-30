CREATE TABLE [dbo].[Local_MPWS_KIT_KitStatuses] (
    [Kit_Status_Id]   INT          IDENTITY (1, 1) NOT NULL,
    [Kit_status_Desc] VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([Kit_Status_Id] ASC)
);

