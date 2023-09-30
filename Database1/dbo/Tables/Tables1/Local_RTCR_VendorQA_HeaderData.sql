CREATE TABLE [dbo].[Local_RTCR_VendorQA_HeaderData] (
    [VQAHeaderId]    INT           IDENTITY (1, 1) NOT NULL,
    [GCAS]           VARCHAR (25)  NULL,
    [SupplierNumber] VARCHAR (50)  NULL,
    [LineName]       VARCHAR (50)  NULL,
    [Timestamp]      DATETIME      NULL,
    [MPMPNumber]     VARCHAR (50)  NULL,
    [StatusId]       INT           NOT NULL,
    [UserId]         INT           NOT NULL,
    [ModifiedOn]     DATETIME      NOT NULL,
    [ErrorMessage]   VARCHAR (255) NULL,
    [ReprocessTime]  DATETIME      NULL,
    [PGSendTime]     DATETIME      NULL,
    CONSTRAINT [LocalRTCRVendorQAHeaderData_PK_VQAHeaderId] PRIMARY KEY CLUSTERED ([VQAHeaderId] ASC),
    CONSTRAINT [Local_RTCR_VendorQA_HeaderData_FK_StatusId] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[Local_RTCR_VendorQA_Status] ([StatusId]),
    CONSTRAINT [Local_RTCR_VendorQA_HeaderData_FK_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE NONCLUSTERED INDEX [LocalRTCRVendorQAHeaderData_IDX_GCAS]
    ON [dbo].[Local_RTCR_VendorQA_HeaderData]([GCAS] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalRTCRVendorQAHeaderData_IDX_SupplierNumber]
    ON [dbo].[Local_RTCR_VendorQA_HeaderData]([SupplierNumber] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalRTCRVendorQAHeaderData_IDX_LineName]
    ON [dbo].[Local_RTCR_VendorQA_HeaderData]([LineName] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalRTCRVendorQAHeaderData_IDX_Timestamp]
    ON [dbo].[Local_RTCR_VendorQA_HeaderData]([Timestamp] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalRTCRVendorQAHeaderData_IDX_UserId]
    ON [dbo].[Local_RTCR_VendorQA_HeaderData]([UserId] ASC);


GO

CREATE TRIGGER [dbo].[Local_RTCR_VendorQA_HeaderData_History_Upd] ON  [dbo].[Local_RTCR_VendorQA_HeaderData]
FOR UPDATE
AS
	INSERT INTO dbo.Local_RTCR_VendorQA_HeaderData_History
	(	
		VQAHeaderId		,
		GCAS			,
		SupplierNumber	,
		LineName		,
		Timestamp		,
		PGSendTime		,
		MPMPNumber		,
		ReprocessTime	,
		StatusId		,
		UserId			,
		ModifiedOn		,
		ErrorMessage	,
		DBTT_Id
	)
	SELECT	VQAHeaderId		,
			GCAS			,
			SupplierNumber	,
			LineName		,
			Timestamp		,
			PGSendTime		,
			MPMPNumber		,
			ReprocessTime	,
			StatusId		,
			UserId			,
			GETDATE()		,
			ErrorMessage	,
			3 --Database Table Trigger ID for UPD function	
	FROM	Inserted
GO

CREATE TRIGGER [dbo].[Local_RTCR_VendorQA_HeaderData_History_Ins] ON  [dbo].[Local_RTCR_VendorQA_HeaderData]
FOR INSERT
AS
	INSERT INTO dbo.Local_RTCR_VendorQA_HeaderData_History
	(	
		VQAHeaderId		,
		GCAS			,
		SupplierNumber	,
		LineName		,
		Timestamp		,
		PGSendTime		,
		MPMPNumber		,
		ReprocessTime	,
		StatusId		,
		UserId			,
		ModifiedOn		,
		ErrorMessage	,
		DBTT_Id
	)
	SELECT	VQAHeaderId		,
			GCAS			,
			SupplierNumber	,
			LineName		,
			Timestamp		,
			PGSendTime		,
			MPMPNumber		,
			ReprocessTime	,
			StatusId		,
			UserId			,
			GETDATE()		,
			Errormessage	,
			2 --Database Table Trigger ID for INS function		
	FROM	Inserted
GO

CREATE TRIGGER [dbo].[Local_RTCR_VendorQA_HeaderData_History_Del] ON  [dbo].[Local_RTCR_VendorQA_HeaderData]
FOR DELETE
AS
	INSERT INTO dbo.Local_RTCR_VendorQA_HeaderData_History
	(	
		VQAHeaderId		,
		GCAS			,
		SupplierNumber	,
		LineName		,
		Timestamp		,
		PGSendTime		,
		MPMPNumber		,
		ReprocessTime	,
		StatusId		,
		UserId			,
		ModifiedOn		,
		ErrorMessage	,
		DBTT_Id
	)
	SELECT	VQAHeaderId		,
			GCAS			,
			SupplierNumber	,
			LineName		,
			Timestamp		,
			PGSendTime		,
			MPMPNumber		,
			ReprocessTime	,
			StatusId		,
			UserId			,
			GETDATE()		,
			ErrorMessage	,
			4 --Database Table Trigger ID for DEL function	
	FROM	Deleted