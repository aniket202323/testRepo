CREATE TABLE [dbo].[Local_RTCR_VendorQA_TestDebugging] (
    [VQADebugId]      INT          IDENTITY (1, 1) NOT NULL,
    [VQAHeaderId]     INT          NULL,
    [PUId]            INT          NULL,
    [VQATestId]       INT          NULL,
    [DataName]        VARCHAR (50) NULL,
    [DataType]        VARCHAR (50) NULL,
    [DataContents]    VARCHAR (25) NULL,
    [VarId]           INT          NULL,
    [UDEId]           INT          NULL,
    [HeaderTimestamp] DATETIME     NULL,
    [TestId]          INT          NULL,
    [GEReturnCode]    INT          NULL,
    [ExecuteTime]     DATETIME     NULL,
    CONSTRAINT [LocalRTCRVendorQATestDebugging_PK_VQADebugId] PRIMARY KEY CLUSTERED ([VQADebugId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LocalRTCRVendorQATestDebugging_IDX_VQAHeaderId]
    ON [dbo].[Local_RTCR_VendorQA_TestDebugging]([VQAHeaderId] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalRTCRVendorQATestDebugging_IDX_HeaderTimestamp]
    ON [dbo].[Local_RTCR_VendorQA_TestDebugging]([DataName] ASC);

