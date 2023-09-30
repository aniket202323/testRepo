CREATE TABLE [dbo].[Local_RTCR_VendorQA_TestData_History] (
    [VQAHistTestId] INT           IDENTITY (1, 1) NOT NULL,
    [VQATestId]     INT           NOT NULL,
    [VQAHeaderId]   INT           NOT NULL,
    [DataName]      VARCHAR (100) NULL,
    [DataValue]     VARCHAR (25)  NULL,
    [DataMin]       VARCHAR (25)  NULL,
    [DataAvg]       VARCHAR (25)  NULL,
    [DataMax]       VARCHAR (25)  NULL,
    [NumSamples]    INT           NULL,
    [TimeTaken]     DATETIME      NULL,
    [UoM]           VARCHAR (15)  NULL,
    [Use]           VARCHAR (255) NULL,
    CONSTRAINT [LocalRTCRVendorQATestDataHistory_PK_VQAHistTestId] PRIMARY KEY CLUSTERED ([VQAHistTestId] ASC)
);


GO

CREATE TRIGGER [dbo].[Local_RTCR_VendorQA_TestData_History_UpdDel]
 ON  [dbo].[Local_RTCR_VendorQA_TestData_History]
  INSTEAD OF UPDATE,DELETE
  AS
 	 DECLARE @Last_Identity INT