CREATE TABLE [ncr].[defect_property_value] (
    [id]                     BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]             VARCHAR (255) NULL,
    [created_on]             DATETIME2 (7) NULL,
    [last_modified_by]       VARCHAR (255) NULL,
    [last_modified_on]       DATETIME2 (7) NULL,
    [version]                INT           NULL,
    [property_definition_id] VARCHAR (255) NULL,
    [value]                  VARCHAR (255) NULL,
    [origin_id]              BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__defect_pr__origi__4E88ABD4] FOREIGN KEY ([origin_id]) REFERENCES [ncr].[defect] ([id])
);


GO

CREATE TRIGGER [ncr].[defect_property_value_history_del]
	ON  [ncr].[defect_property_value]
	FOR DELETE
AS 
BEGIN
	SET NOCOUNT ON
	IF (Context_info() = 0x446174615075726765) RETURN --DataPurge

	INSERT INTO defect_property_value_history(
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,[property_definition_id]
			,[value]
			,[origin_id]
			,[defect_property_value_id]
			,[Modified_On]
			,[DBTT_Id]
			,[Column_Updated_BitMask]
			)
		SELECT  
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,[property_definition_id]
			,[value]
			,[origin_id]
			,[id]
			,GETUTCDATE()
			,4
			,COLUMNS_UPDATED()
		FROM deleted
END

GO


CREATE TRIGGER [ncr].[defect_property_value_history_ins]
	ON  [ncr].[defect_property_value]
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
	OR UPDATE([property_definition_id])
	OR UPDATE([value])
	OR UPDATE([origin_id])
	OR UPDATE([id]))
	BEGIN
	INSERT INTO defect_property_value_history(
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,[property_definition_id]
			,[value]
			,[defect_property_value_id]
			,[Modified_On]
			,[DBTT_Id]
			,[Column_Updated_BitMask]
			)
		SELECT  
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,[property_definition_id]
			,[value]
			,[id]
			,GETUTCDATE()
			,2
			,COLUMNS_UPDATED()
		FROM inserted
		END
END


GO


CREATE TRIGGER [ncr].[defect_property_value_history_upd]
	ON  [ncr].[defect_property_value]
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
	OR UPDATE([property_definition_id])
	OR UPDATE([value])
	OR UPDATE([origin_id])
	OR UPDATE([id]))
	BEGIN
	INSERT INTO defect_property_value_history(
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,[property_definition_id]
			,[value]
			,[origin_id]
			,[defect_property_value_id]
			,[Modified_On]
			,[DBTT_Id]
			,[Column_Updated_BitMask]
			)
		SELECT  
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,[property_definition_id]
			,[value]
			,[origin_id]
			,[id]
			,GETUTCDATE()
			,3
			,COLUMNS_UPDATED()
		FROM inserted
		END
END

