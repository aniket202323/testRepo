CREATE TABLE [ncr].[non_conformance] (
    [id]                      BIGINT         IDENTITY (1, 1) NOT NULL,
    [created_by]              VARCHAR (255)  NULL,
    [created_on]              DATETIME2 (7)  NULL,
    [last_modified_by]        VARCHAR (255)  NULL,
    [last_modified_on]        DATETIME2 (7)  NULL,
    [version]                 INT            NULL,
    [description]             VARCHAR (1000) NULL,
    [name]                    VARCHAR (255)  NULL,
    [source]                  VARCHAR (255)  NULL,
    [non_conformance_type_id] BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__non_confo__non_c__571DF1D5] FOREIGN KEY ([non_conformance_type_id]) REFERENCES [ncr].[non_conformance_type] ([id])
);


GO

CREATE TRIGGER [ncr].[non_conformance_history_del]
	ON  [ncr].[non_conformance]
	FOR DELETE
AS 
BEGIN
	SET NOCOUNT ON
	IF (Context_info() = 0x446174615075726765) RETURN --DataPurge

	INSERT INTO non_conformance_history(
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,[description]
			,[name]
			,[source]
			,[non_conformance_type_id]
			,[non_conformance_id]
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
			,[description]
			,[name]
			,[source]
			,[non_conformance_type_id]
			,[id]
			,GETUTCDATE()
			,4
			,COLUMNS_UPDATED()
	FROM deleted
END

GO

CREATE TRIGGER [ncr].[non_conformance_history_upd]
	ON  [ncr].[non_conformance]
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
	OR UPDATE([description]) 
	OR UPDATE([name]) 
	OR UPDATE([source]) 
	OR UPDATE([non_conformance_type_id])
	OR UPDATE([id])) 
	BEGIN
		INSERT INTO non_conformance_history(
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,[description]
			,[name]
			,[source]
			,[non_conformance_type_id]
			,[non_conformance_id]
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
			,[description]
			,[name]
			,[source]
			,[non_conformance_type_id]
			,[id]
			,GETUTCDATE()
			,3
			,COLUMNS_UPDATED()
		FROM Inserted
	END
END

GO

CREATE TRIGGER [ncr].[non_conformance_history_ins]
	ON  [ncr].[non_conformance]
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
	OR UPDATE([description]) 
	OR UPDATE([name]) 
	OR UPDATE([source]) 
	OR UPDATE([non_conformance_type_id])
	OR UPDATE([id])) 
	BEGIN
		INSERT INTO non_conformance_history(
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,[description]
			,[name]
			,[source]
			,[non_conformance_type_id]
			,[non_conformance_id]
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
			,[description]
			,[name]
			,[source]
			,[non_conformance_type_id]
			,[id]
			,GETUTCDATE()
			,2
			,COLUMNS_UPDATED()
		FROM Inserted
	END
END
