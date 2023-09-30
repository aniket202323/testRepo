CREATE TABLE [ncr].[defect] (
    [id]                                BIGINT         IDENTITY (1, 1) NOT NULL,
    [created_by]                        VARCHAR (255)  NULL,
    [created_on]                        DATETIME2 (7)  NULL,
    [last_modified_by]                  VARCHAR (255)  NULL,
    [last_modified_on]                  DATETIME2 (7)  NULL,
    [version]                           INT            NULL,
    [affected_object_id]                VARCHAR (255)  NULL,
    [affected_quantity]                 FLOAT (53)     NULL,
    [affected_quantity_unit_of_measure] VARCHAR (255)  NULL,
    [comment_id]                        VARCHAR (255)  NULL,
    [defect_reason_level1_id]           VARCHAR (255)  NULL,
    [defect_reason_level2_id]           VARCHAR (255)  NULL,
    [defect_reason_level3_id]           VARCHAR (255)  NULL,
    [defect_reason_level4_id]           VARCHAR (255)  NULL,
    [description]                       NVARCHAR (MAX) NULL,
    [location_id]                       VARCHAR (255)  NULL,
    [location_type]                     VARCHAR (255)  NULL,
    [reported_by]                       VARCHAR (255)  NULL,
    [status]                            VARCHAR (255)  NULL,
    [summary]                           NVARCHAR (255) NULL,
    [defect_type_id]                    BIGINT         NULL,
    [non_conformance_id]                BIGINT         NULL,
    [affected_object_type]              VARCHAR (255)  NULL,
    [defect_context_type]               NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__defect__defect_t__49C3F6B7] FOREIGN KEY ([defect_type_id]) REFERENCES [ncr].[defect_type] ([id]),
    CONSTRAINT [FK__defect__non_conf__4AB81AF0] FOREIGN KEY ([non_conformance_id]) REFERENCES [ncr].[non_conformance] ([id])
);


GO

CREATE TRIGGER [ncr].[defect_history_upd]
       ON  [ncr].[defect]
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
       OR UPDATE([affected_object_id]) 
       OR UPDATE([affected_quantity]) 
       OR UPDATE([affected_quantity_unit_of_measure])
       OR UPDATE([comment_id])
       OR UPDATE([defect_reason_level1_id])
       OR UPDATE([defect_reason_level2_id])
       OR UPDATE([defect_reason_level3_id])
       OR UPDATE([defect_reason_level4_id])
       OR UPDATE([description])
       OR UPDATE([location_id])
       OR UPDATE([location_type])
       OR UPDATE([reported_by])
       OR UPDATE([status])
       OR UPDATE([summary])
       OR UPDATE([defect_type_id])
       OR UPDATE([non_conformance_id])
       OR UPDATE([id])) 
       BEGIN
       IF NOT EXISTS(SELECT 1 FROM ncr.defect_history WHERE [status] = (SELECT [status] FROM Inserted) AND defect_id = (SELECT id FROM Inserted) AND [version] = (SELECT [version] FROM Inserted))
       BEGIN
            INSERT INTO ncr.defect_history(
                    [created_by]
                    ,[created_on]
                    ,[last_modified_by]
                    ,[last_modified_on]
                    ,[version]
                    ,[affected_object_id]
                    ,[affected_quantity]
                    ,[affected_quantity_unit_of_measure]
                    ,[comment_id]
                    ,[defect_reason_level1_id]
                    ,[defect_reason_level2_id]
                    ,[defect_reason_level3_id]
                    ,[defect_reason_level4_id]
                    ,[description]
                    ,[location_id]
                    ,[location_type]
                    ,[reported_by]
                    ,[status]
                    ,[summary]
                    ,[defect_type_id]
                    ,[non_conformance_id]
					,[affected_object_type]
					,[defect_context_type]
                    ,[defect_id]
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
                    ,[affected_object_id]
                    ,[affected_quantity]
                    ,[affected_quantity_unit_of_measure]
                    ,[comment_id]
                    ,[defect_reason_level1_id]
                    ,[defect_reason_level2_id]
                    ,[defect_reason_level3_id]
                    ,[defect_reason_level4_id]
                    ,[description]
                    ,[location_id]
                    ,[location_type]
                    ,[reported_by]
                    ,[status]
                    ,[summary]
                    ,[defect_type_id]
                    ,[non_conformance_id]
					,[affected_object_type]
					,[defect_context_type]
                    ,[id]
                    ,GETUTCDATE()
                    ,3
                    ,COLUMNS_UPDATED()
            FROM Inserted
        END
    END
END

GO

CREATE TRIGGER [ncr].[defect_history_del]
	ON  [ncr].[defect]
	FOR DELETE
AS 
BEGIN
	SET NOCOUNT ON
	IF (Context_info() = 0x446174615075726765) RETURN --DataPurge

	INSERT INTO defect_history(
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,[affected_object_id]
			,[affected_quantity]
			,[affected_quantity_unit_of_measure]
			,[comment_id]
			,[defect_reason_level1_id]
			,[defect_reason_level2_id]
			,[defect_reason_level3_id]
			,[defect_reason_level4_id]
			,[description]
			,[location_id]
			,[location_type]
			,[reported_by]
			,[status]
			,[summary]
			,[defect_type_id]
			,[non_conformance_id]
			,[affected_object_type]
			,[defect_context_type]
			,[defect_id]
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
			,[affected_object_id]
			,[affected_quantity]
			,[affected_quantity_unit_of_measure]
			,[comment_id]
			,[defect_reason_level1_id]
			,[defect_reason_level2_id]
			,[defect_reason_level3_id]
			,[defect_reason_level4_id]
			,[description]
			,[location_id]
			,[location_type]
			,[reported_by]
			,[status]
			,[summary]
			,[defect_type_id]
			,[non_conformance_id]
			,[affected_object_type]
			,[defect_context_type]
			,[id]
			,GETUTCDATE()
			,4
			,COLUMNS_UPDATED()
		FROM deleted
END

GO

CREATE TRIGGER [ncr].[defect_history_ins]
	ON  [ncr].[defect]
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
	OR UPDATE([affected_object_id]) 
	OR UPDATE([affected_quantity]) 
	OR UPDATE([affected_quantity_unit_of_measure])
	OR UPDATE([comment_id])
	OR UPDATE([defect_reason_level1_id])
	OR UPDATE([defect_reason_level2_id])
	OR UPDATE([defect_reason_level3_id])
	OR UPDATE([defect_reason_level4_id])
	OR UPDATE([description])
	OR UPDATE([location_id])
	OR UPDATE([location_type])
	OR UPDATE([reported_by])
	OR UPDATE([status])
	OR UPDATE([summary])
	OR UPDATE([defect_type_id])
	OR UPDATE([non_conformance_id])
	OR UPDATE([id])) 
	BEGIN
		INSERT INTO defect_history(
			 [created_by]
			,[created_on]
			,[last_modified_by]
			,[last_modified_on]
			,[version]
			,[affected_object_id]
			,[affected_quantity]
			,[affected_quantity_unit_of_measure]
			,[comment_id]
			,[defect_reason_level1_id]
			,[defect_reason_level2_id]
			,[defect_reason_level3_id]
			,[defect_reason_level4_id]
			,[description]
			,[location_id]
			,[location_type]
			,[reported_by]
			,[status]
			,[summary]
			,[defect_type_id]
			,[non_conformance_id]
			,[affected_object_type]
			,[defect_context_type]
			,[defect_id]
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
			,[affected_object_id]
			,[affected_quantity]
			,[affected_quantity_unit_of_measure]
			,[comment_id]
			,[defect_reason_level1_id]
			,[defect_reason_level2_id]
			,[defect_reason_level3_id]
			,[defect_reason_level4_id]
			,[description]
			,[location_id]
			,[location_type]
			,[reported_by]
			,[status]
			,[summary]
			,[defect_type_id]
			,[non_conformance_id]
			,[affected_object_type]
			,[defect_context_type]
			,[id]
			,GETUTCDATE()
			,2
			,COLUMNS_UPDATED()
		FROM Inserted
	END
END
