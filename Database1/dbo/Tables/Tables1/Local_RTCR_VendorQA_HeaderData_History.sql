CREATE TABLE [dbo].[Local_RTCR_VendorQA_HeaderData_History] (
    [VQAHistHeaderId] INT           IDENTITY (1, 1) NOT NULL,
    [VQAHeaderId]     INT           NOT NULL,
    [GCAS]            VARCHAR (25)  NULL,
    [SupplierNumber]  VARCHAR (50)  NULL,
    [LineName]        VARCHAR (50)  NULL,
    [Timestamp]       DATETIME      NULL,
    [MPMPNumber]      VARCHAR (50)  NULL,
    [StatusId]        INT           NOT NULL,
    [UserId]          INT           NOT NULL,
    [ModifiedOn]      DATETIME      NOT NULL,
    [DBTT_Id]         INT           NULL,
    [ErrorMessage]    VARCHAR (255) NULL,
    [ReprocessTime]   DATETIME      NULL,
    [PGSendTime]      DATETIME      NULL,
    CONSTRAINT [LocalRTCRVendorQAHeaderDataHistory_PK_VQAHistHeaderId] PRIMARY KEY CLUSTERED ([VQAHistHeaderId] ASC),
    CONSTRAINT [Local_RTCR_VendorQA_HeaderData_History_FK_StatusId] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[Local_RTCR_VendorQA_Status] ([StatusId]),
    CONSTRAINT [Local_RTCR_VendorQA_HeaderData_History_FK_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO

CREATE TRIGGER [dbo].[Local_RTCR_VendorQA_HeaderData_History_UpdDel]
 ON  [dbo].[Local_RTCR_VendorQA_HeaderData_History]
  INSTEAD OF UPDATE,DELETE
  AS
 	 DECLARE @Last_Identity INT