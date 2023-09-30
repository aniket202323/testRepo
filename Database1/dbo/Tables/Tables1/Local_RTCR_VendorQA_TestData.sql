CREATE TABLE [dbo].[Local_RTCR_VendorQA_TestData] (
    [VQATestId]   INT            IDENTITY (1, 1) NOT NULL,
    [VQAHeaderId] INT            NOT NULL,
    [DataName]    VARCHAR (100)  NULL,
    [DataValue]   VARCHAR (25)   NULL,
    [DataMin]     VARCHAR (25)   NULL,
    [DataAvg]     VARCHAR (25)   NULL,
    [DataMax]     VARCHAR (25)   NULL,
    [NumSamples]  INT            NULL,
    [TimeTaken]   DATETIME       NULL,
    [UoM]         VARCHAR (15)   NULL,
    [Use]         VARCHAR (1000) NULL,
    CONSTRAINT [LocalRTCRVendorQATestData_PK_VQATestId] PRIMARY KEY CLUSTERED ([VQATestId] ASC),
    CONSTRAINT [Local_RTCR_VendorQA_TestData_FK_VQAHeaderId] FOREIGN KEY ([VQAHeaderId]) REFERENCES [dbo].[Local_RTCR_VendorQA_HeaderData] ([VQAHeaderId])
);


GO
CREATE NONCLUSTERED INDEX [LocalRTCRVendorQATestData_IDX_VQAHeaderId]
    ON [dbo].[Local_RTCR_VendorQA_TestData]([VQAHeaderId] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalRTCRVendorQATestData_IDX_DataName]
    ON [dbo].[Local_RTCR_VendorQA_TestData]([DataName] ASC);


GO

CREATE TRIGGER [dbo].[Local_RTCR_VendorQA_TestData_History_Ins] ON  [dbo].[Local_RTCR_VendorQA_TestData]
FOR INSERT
AS
	INSERT INTO dbo.Local_RTCR_VendorQA_TestData_History
	(	
		VQATestId,
		VQAHeaderId,
		DataName,
		DataValue,
		DataMin,
		DataAvg,
		DataMax,
		NumSamples,
		TimeTaken,
		UoM,
		[Use]
	)
	SELECT	VQATestId,
			VQAHeaderId,
			DataName,
			DataValue,
			DataMin,
			DataAvg,
			DataMax,
			NumSamples,
			TimeTaken,
			UoM,
			[Use]
						
	FROM	Inserted
GO

CREATE TRIGGER [dbo].[Local_RTCR_VendorQA_TestData_History_Upd] ON  [dbo].[Local_RTCR_VendorQA_TestData]
FOR UPDATE
AS
	INSERT INTO dbo.Local_RTCR_VendorQA_TestData_History
	(	
		VQATestId,
		VQAHeaderId,
		DataName,
		DataValue,
		DataMin,
		DataAvg,
		DataMax,
		NumSamples,
		TimeTaken,
		UoM,
		[Use]
	)
	SELECT	VQATestId,
			VQAHeaderId,
			DataName,
			DataValue,
			DataMin,
			DataAvg,
			DataMax,
			NumSamples,
			TimeTaken,
			UoM,
			[Use]
						
	FROM	Inserted
GO

CREATE TRIGGER [dbo].[Local_RTCR_VendorQA_TestData_History_Del] ON  [dbo].[Local_RTCR_VendorQA_TestData]
FOR DELETE
AS
	INSERT INTO dbo.Local_RTCR_VendorQA_TestData_History
	(	
		VQATestId,
		VQAHeaderId,
		DataName,
		DataValue,
		DataMin,
		DataAvg,
		DataMax,
		NumSamples,
		TimeTaken,
		UoM,
		[Use]
	)
	SELECT	VQATestId,
			VQAHeaderId,
			DataName,
			DataValue,
			DataMin,
			DataAvg,
			DataMax,
			NumSamples,
			TimeTaken,
			UoM,
			[Use]
						
	FROM	Deleted