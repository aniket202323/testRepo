CREATE TABLE [dbo].[Local_PrIME_OpenRequests] (
    [OpenTableId]       INT             IDENTITY (1, 1) NOT NULL,
    [RequestId]         VARCHAR (50)    NULL,
    [PrIMEReturnCode]   INT             NULL,
    [RequestTime]       DATETIME        NOT NULL,
    [LocationId]        VARCHAR (50)    NOT NULL,
    [CurrentLocation]   VARCHAR (50)    NULL,
    [ULID]              VARCHAR (50)    NULL,
    [Batch]             VARCHAR (50)    NULL,
    [ProcessOrder]      VARCHAR (50)    NULL,
    [PrimaryGCas]       VARCHAR (50)    NOT NULL,
    [AlternateGCas]     VARCHAR (50)    NULL,
    [GCas]              VARCHAR (50)    NULL,
    [QuantityValue]     DECIMAL (19, 5) NOT NULL,
    [QuantityUoM]       VARCHAR (50)    NULL,
    [Status]            VARCHAR (50)    NULL,
    [EstimatedDelivery] DATETIME        NULL,
    [LastUpdatedTime]   DATETIME        NULL,
    [UserId]            INT             NULL,
    [EventId]           INT             NULL,
    [Comment]           VARCHAR (8000)  NULL,
    [PlantID]           VARCHAR (50)    NULL,
    [WarehouseID]       VARCHAR (50)    NULL,
    [ResponseTime]      DATETIME        NULL,
    CONSTRAINT [LocalPrIMEOpenRequests_PK_OpenTableId] PRIMARY KEY CLUSTERED ([OpenTableId] ASC),
    CONSTRAINT [UQ_Local_PrIME_OpenRequests_RequestId] UNIQUE NONCLUSTERED ([RequestId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequests_IDX_RequestId]
    ON [dbo].[Local_PrIME_OpenRequests]([RequestId] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequests_IDX_LocationId]
    ON [dbo].[Local_PrIME_OpenRequests]([LocationId] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequests_IDX_ProcessOrder]
    ON [dbo].[Local_PrIME_OpenRequests]([ProcessOrder] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequests_IDX_RequestTime]
    ON [dbo].[Local_PrIME_OpenRequests]([RequestTime] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequests_IDX_EstimatedDelivery]
    ON [dbo].[Local_PrIME_OpenRequests]([EstimatedDelivery] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequests_IDX_LastUpdatedTime]
    ON [dbo].[Local_PrIME_OpenRequests]([LastUpdatedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequests_IDX_EventId]
    ON [dbo].[Local_PrIME_OpenRequests]([EventId] ASC);


GO

CREATE TRIGGER [dbo].[LocalPrIME_OpenRequests_History_Upd] ON  [dbo].[Local_PrIME_OpenRequests]
FOR UPDATE
AS
	INSERT INTO dbo.Local_PrIME_OpenRequests_History
	(
		OpenTableId			,
		RequestId			,
		PrIMEReturnCode		,
		RequestTime			,
		ResponseTime		,
		LocationId			,
		CurrentLocation		,
		PlantID				,
		WarehouseID			,
		ULID				,
		Batch				,
		ProcessOrder		,
		PrimaryGCas			,
		AlternateGCas		,
		GCas				,
		QuantityValue		,
		QuantityUoM			,
		Status				,
		EstimatedDelivery	,
		LastUpdatedTime		,
		UserId				,
		EventId				,
		Comment				,
		ModifiedOn			,
		DBTT_ID
	)
	SELECT	OpenTableId			,
			RequestId			,
			PrIMEReturnCode		,
			RequestTime			,
			ResponseTime		,
			LocationId			,
			CurrentLocation		,
			PlantID				,
			WarehouseID			,
			ULID				,
			Batch				,
			ProcessOrder		,
			PrimaryGCas			,
			AlternateGCas		,
			GCas				,
			QuantityValue		,
			QuantityUoM			,
			Status				,
			EstimatedDelivery	,
			LastUpdatedTime		,
			UserId				,
			EventId				,
			Comment				,
			GETDATE()			,
			3		
	FROM	Inserted
GO

CREATE TRIGGER [dbo].[LocalPrIME_OpenRequests_History_Ins] ON  [dbo].[Local_PrIME_OpenRequests]
FOR INSERT
AS
	INSERT INTO dbo.Local_PrIME_OpenRequests_History
	(
		OpenTableId			,
		RequestId			,
		PrIMEReturnCode		,
		RequestTime			,
		ResponseTime		,
		LocationId			,
		CurrentLocation		,
		PlantID				,
		WarehouseID			,
		ULID				,
		Batch				,
		ProcessOrder		,
		PrimaryGCas			,
		AlternateGCas		,
		GCas				,
		QuantityValue		,
		QuantityUoM			,
		Status				,
		EstimatedDelivery	,
		LastUpdatedTime		,
		UserId				,
		EventId				,
		Comment				,
		ModifiedOn			,
		DBTT_ID
	)
	SELECT	OpenTableId			,
			RequestId			,
			PrIMEReturnCode		,
			RequestTime			,
			ResponseTime		,
			LocationId			,
			CurrentLocation		,
			PlantID				,
			WarehouseID			,
			ULID				,
			Batch				,
			ProcessOrder		,
			PrimaryGCas			,
			AlternateGCas		,
			GCas				,
			QuantityValue		,
			QuantityUoM			,
			Status				,
			EstimatedDelivery	,
			LastUpdatedTime		,
			UserId				,
			EventId				,
			Comment				,
			GETDATE()			,
			2		
	FROM	Inserted
GO

CREATE TRIGGER [dbo].[LocalPrIME_OpenRequests_History_Del] ON  [dbo].[Local_PrIME_OpenRequests]
FOR DELETE
AS
	INSERT INTO dbo.Local_PrIME_OpenRequests_History
	(	
		OpenTableId			,
		RequestId			,
		PrIMEReturnCode		,
		RequestTime			,
		ResponseTime		,
		LocationId			,
		CurrentLocation		,
		PlantID				,
		WarehouseID			,
		ULID				,
		Batch				,
		ProcessOrder		,
		PrimaryGCas			,
		AlternateGCas		,
		GCas				,
		QuantityValue		,
		QuantityUoM			,
		Status				,
		EstimatedDelivery	,
		LastUpdatedTime		,
		UserId				,
		EventId				,
		[Comment]			,
		ModifiedOn			,
		DBTT_ID
	)
	SELECT	OpenTableId			,
			RequestId			,
			PrIMEReturnCode		,
			RequestTime			,
			ResponseTime		,
			LocationId			,
			CurrentLocation		,
			PlantID				,
			WarehouseID			,
			ULID				,
			Batch				,
			ProcessOrder		,
			PrimaryGCas			,
			AlternateGCas		,
			GCas				,
			QuantityValue		,
			QuantityUoM			,
			Status				,
			EstimatedDelivery	,
			LastUpdatedTime		,
			UserId				,
			EventId				,
			[Comment]			,
			GETDATE()			,
			4	
	FROM	Deleted
	