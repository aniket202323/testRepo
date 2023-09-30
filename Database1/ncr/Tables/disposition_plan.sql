CREATE TABLE [ncr].[disposition_plan] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]       VARCHAR (255) NULL,
    [created_on]       DATETIME2 (7) NULL,
    [last_modified_by] VARCHAR (255) NULL,
    [last_modified_on] DATETIME2 (7) NULL,
    [version]          INT           NULL,
    [name]             VARCHAR (255) NULL,
    [requires_review]  BIT           NULL,
    [reviewed]         BIT           NULL,
    [reviewed_by]      VARCHAR (255) NULL,
    [reviewed_on]      DATETIME2 (7) NULL,
    [source]           VARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);


GO

CREATE TRIGGER [ncr].[disposition_plan_history_del]
	ON  [ncr].[disposition_plan]
	FOR DELETE
AS 
BEGIN
	SET NOCOUNT ON
	IF (Context_info() = 0x446174615075726765) RETURN --DataPurge

	INSERT INTO disposition_plan_history(
			[created_by]
           ,[created_on]
           ,[last_modified_by]
           ,[last_modified_on]
           ,[version]
           ,[column_updated_bitmask]
           ,[dbtt_id]
           ,[modified_on]
           ,[disposition_plan_id]
           ,[name]
           ,[requires_review]
           ,[reviewed]
           ,[reviewed_by]
           ,[reviewed_on]
           ,[source])
		SELECT  
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,COLUMNS_UPDATED()
			,4
			,GETUTCDATE()
			,[id]
			,[name]
			,[requires_review]
			,[reviewed]
			,[reviewed_by]
			,[reviewed_on]
			,[source]
		FROM deleted 
END

GO

CREATE TRIGGER [ncr].[disposition_plan_history_upd]
	ON  [ncr].[disposition_plan]
	FOR UPDATE
AS 
BEGIN
	SET NOCOUNT ON
	IF (Context_info() = 0x446174615075726765) RETURN --DataPurge

	IF (UPDATE([created_by]) 
	OR UPDATE([created_on]) 
	OR UPDATE([last_modified_by])
	OR UPDATE([last_modified_on])
	OR UPDATE([version]) 
	OR UPDATE([name]) 
	OR UPDATE([requires_review]) 
	OR UPDATE([reviewed])
	OR UPDATE([reviewed_by])
	OR UPDATE([reviewed_on])
	OR UPDATE([id])) 
	BEGIN
		INSERT INTO disposition_plan_history(
			[created_by]
           ,[created_on]
           ,[last_modified_by]
           ,[last_modified_on]
           ,[version]
           ,[column_updated_bitmask]
           ,[dbtt_id]
           ,[modified_on]
           ,[disposition_plan_id]
           ,[name]
           ,[requires_review]
           ,[reviewed]
           ,[reviewed_by]
           ,[reviewed_on]
           ,[source])
		SELECT  
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,COLUMNS_UPDATED()
			,3
			,GETUTCDATE()
			,[id]
			,[name]
			,[requires_review]
			,[reviewed]
			,[reviewed_by]
			,[reviewed_on]
			,[source]
		FROM Inserted 
	END
END

GO

CREATE TRIGGER [ncr].[disposition_plan_history_ins]
	ON  [ncr].[disposition_plan]
	FOR INSERT
AS 
BEGIN
	SET NOCOUNT ON
	IF (Context_info() = 0x446174615075726765) RETURN --DataPurge

	IF (UPDATE([created_by]) 
	OR UPDATE([created_on]) 
	OR UPDATE([last_modified_by])
	OR UPDATE([last_modified_on])
	OR UPDATE([version]) 
	OR UPDATE([name]) 
	OR UPDATE([requires_review]) 
	OR UPDATE([reviewed]) 
	OR UPDATE([reviewed_by])
	OR UPDATE([reviewed_on])
	OR UPDATE([id])) 
	BEGIN
		INSERT INTO disposition_plan_history(
			[created_by]
           ,[created_on]
           ,[last_modified_by]
           ,[last_modified_on]
           ,[version]
           ,[column_updated_bitmask]
           ,[dbtt_id]
           ,[modified_on]
           ,[disposition_plan_id]
           ,[name]
           ,[requires_review]
           ,[reviewed]
           ,[reviewed_by]
           ,[reviewed_on]
           ,[source])
		SELECT  
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,COLUMNS_UPDATED()
			,2
			,GETUTCDATE()
			,[id]
			,[name]
			,[requires_review]
			,[reviewed]
			,[reviewed_by]
			,[reviewed_on]
			,[source]
		FROM Inserted 
	END
END
