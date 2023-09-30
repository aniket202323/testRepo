CREATE TABLE [dbo].[Local_RTCR_VendorQA_Status] (
    [StatusId]   INT          IDENTITY (1, 1) NOT NULL,
    [StatusDesc] VARCHAR (50) NOT NULL,
    CONSTRAINT [LocalRTCRVendorQAStatus_PK_StatusId] PRIMARY KEY CLUSTERED ([StatusId] ASC)
);

