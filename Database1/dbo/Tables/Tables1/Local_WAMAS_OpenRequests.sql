CREATE TABLE [dbo].[Local_WAMAS_OpenRequests] (
    [OpenTableId]       INT          IDENTITY (1, 1) NOT NULL,
    [RequestId]         VARCHAR (50) NULL,
    [RequestTime]       DATETIME     NOT NULL,
    [LocationId]        VARCHAR (50) NOT NULL,
    [LineId]            VARCHAR (50) NOT NULL,
    [ULID]              VARCHAR (50) NULL,
    [VendorLotId]       VARCHAR (50) NULL,
    [ProcessOrder]      VARCHAR (50) NOT NULL,
    [PrimaryGCas]       VARCHAR (50) NOT NULL,
    [AlternateGCas]     VARCHAR (50) NULL,
    [GCas]              VARCHAR (50) NULL,
    [QuantityValue]     INT          NOT NULL,
    [QuantityUoM]       VARCHAR (50) NOT NULL,
    [Status]            VARCHAR (50) NULL,
    [EstimatedDelivery] DATETIME     NULL,
    [LastUpdatedTime]   DATETIME     NULL,
    [UserId]            INT          NULL,
    CONSTRAINT [LocalWAMASOpenRequests_PK_OpenTableId] PRIMARY KEY CLUSTERED ([OpenTableId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequests_IDX_RequestId]
    ON [dbo].[Local_WAMAS_OpenRequests]([RequestId] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequests_IDX_LocationId]
    ON [dbo].[Local_WAMAS_OpenRequests]([LocationId] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequests_IDX_LineId]
    ON [dbo].[Local_WAMAS_OpenRequests]([LineId] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequests_IDX_ProcessOrder]
    ON [dbo].[Local_WAMAS_OpenRequests]([ProcessOrder] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequests_IDX_RequestTime]
    ON [dbo].[Local_WAMAS_OpenRequests]([RequestTime] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequests_IDX_EstimatedDelivery]
    ON [dbo].[Local_WAMAS_OpenRequests]([EstimatedDelivery] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequests_IDX_LastUpdatedTime]
    ON [dbo].[Local_WAMAS_OpenRequests]([LastUpdatedTime] ASC);


GO

CREATE TRIGGER [dbo].[LocalWAMAS_OpenRequests_History_Upd] ON  [dbo].[Local_WAMAS_OpenRequests]
FOR UPDATE
AS
	INSERT INTO dbo.Local_WAMAS_OpenRequests_History
	(
		OpenTableId,
		RequestId,
		RequestTime,
		LocationId,
		LineId,
		ULID,
		VendorLotId,
		[ProcessOrder],
		PrimaryGCas,
		AlternateGCas,
		GCas,
		[QuantityValue],
		[QuantityUoM],
		[Status],
		EstimatedDelivery,
		LastUpdatedTime,
		UserId,
		ModifiedOn,
		DBTT_ID
	)
	SELECT	OpenTableId,
			RequestId,
			RequestTime,
			LocationId,
			LineId,
			ULID,
			VendorLotId,
			[ProcessOrder],
			PrimaryGCas,
			AlternateGCas,
			GCas,
			[QuantityValue],
			[QuantityUoM],
			[Status],
			EstimatedDelivery,
			LastUpdatedTime,
			UserId,				
			GETDATE(),
			3
			
	FROM	Inserted
GO

CREATE TRIGGER [dbo].[LocalWAMAS_OpenRequests_History_Ins] ON  [dbo].[Local_WAMAS_OpenRequests]
FOR INSERT
AS
	INSERT INTO dbo.Local_WAMAS_OpenRequests_History
	(
		OpenTableId,
		RequestId,
		RequestTime,
		LocationId,
		LineId,
		ULID,
		VendorLotId,
		[ProcessOrder],
		PrimaryGCas,
		AlternateGCas,
		GCas,
		[QuantityValue],
		[QuantityUoM],
		[Status],
		EstimatedDelivery,
		LastUpdatedTime,
		UserId,
		ModifiedOn,
		DBTT_ID
	)
	SELECT	OpenTableId,
			RequestId,
			RequestTime,
			LocationId,
			LineId,
			ULID,
			VendorLotId,
			[ProcessOrder],
			PrimaryGCas,
			AlternateGCas,
			GCas,
			[QuantityValue],
			[QuantityUoM],
			[Status],
			EstimatedDelivery,
			LastUpdatedTime,
			UserId,					-- Placeholder for Event Manager
			GETDATE(),
			2
			
	FROM	Inserted
GO

CREATE TRIGGER [dbo].[LocalWAMAS_OpenRequests_History_Del] ON  [dbo].[Local_WAMAS_OpenRequests]
FOR DELETE
AS
	INSERT INTO dbo.Local_WAMAS_OpenRequests_History
	(	
		OpenTableId,
		RequestId,
		RequestTime,
		LocationId,
		LineId,
		ULID,
		VendorLotId,
		[ProcessOrder],
		PrimaryGCas,
		AlternateGCas,
		GCas,
		[QuantityValue],
		[QuantityUoM],
		[Status],
		EstimatedDelivery,
		LastUpdatedTime,
		UserId,
		ModifiedOn,
		DBTT_ID
	)
	SELECT	OpenTableId,
			RequestId,
			RequestTime,
			LocationId,
			LineId,
			ULID,
			VendorLotId,
			[ProcessOrder],
			PrimaryGCas,
			AlternateGCas,
			GCas,
			[QuantityValue],
			[QuantityUoM],
			[Status],
			EstimatedDelivery,
			LastUpdatedTime,
			UserId,				
			GETDATE(),
			4
			
	FROM	Deleted
	