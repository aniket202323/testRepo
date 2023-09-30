CREATE TABLE [ncr].[disposition_action] (
    [id]                      BIGINT         IDENTITY (1, 1) NOT NULL,
    [created_by]              VARCHAR (255)  NULL,
    [created_on]              DATETIME2 (7)  NULL,
    [last_modified_by]        VARCHAR (255)  NULL,
    [last_modified_on]        DATETIME2 (7)  NULL,
    [version]                 INT            NULL,
    [action_note]             NVARCHAR (MAX) NULL,
    [comment_id]              VARCHAR (255)  NULL,
    [da_reason_level1_id]     VARCHAR (255)  NULL,
    [da_reason_level2_id]     VARCHAR (255)  NULL,
    [da_reason_level3_id]     VARCHAR (255)  NULL,
    [da_reason_level4_id]     VARCHAR (255)  NULL,
    [elapsed_time]            INT            NULL,
    [name]                    VARCHAR (255)  NULL,
    [quantity]                FLOAT (53)     NULL,
    [status]                  VARCHAR (255)  NULL,
    [disposition_plan_id]     BIGINT         NULL,
    [disposition_type_id]     BIGINT         NULL,
    [last_modified_operation] VARCHAR (255)  NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__dispositi__dispo__5165187F] FOREIGN KEY ([disposition_plan_id]) REFERENCES [ncr].[disposition_plan] ([id]),
    CONSTRAINT [FK__dispositi__dispo__52593CB8] FOREIGN KEY ([disposition_type_id]) REFERENCES [ncr].[disposition_type] ([id])
);


GO
CREATE TRIGGER [ncr].[disposition_action_history_upd]
	ON  [ncr].[disposition_action]
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
	OR UPDATE([action_note]) 
	OR UPDATE([comment_id]) 
	OR UPDATE([da_reason_level1_id])
	OR UPDATE([da_reason_level2_id])
	OR UPDATE([da_reason_level3_id])
	OR UPDATE([da_reason_level4_id])
	OR UPDATE([elapsed_time])
	OR UPDATE([name])
	OR UPDATE([quantity])
	OR UPDATE([status]) 
	OR UPDATE([disposition_plan_id])
	OR UPDATE([disposition_type_id])
	OR UPDATE([id])
	OR UPDATE([last_modified_operation])) 
	BEGIN
		INSERT INTO disposition_action_history(
			[created_by]
           ,[created_on]
           ,[last_modified_by]
           ,[last_modified_on]
           ,[version]
           ,[column_updated_bitmask]
           ,[dbtt_id]
           ,[modified_on]
           ,[disposition_action_id]
           ,[comment_id]
           ,[da_reason_level1_id]
           ,[da_reason_level2_id]
           ,[da_reason_level3_id]
           ,[da_reason_level4_id]
           ,[disposition_plan_id]
           ,[disposition_type_id]
           ,[elapsed_time]
           ,[name]
           ,[quantity]
           ,[status]
		   ,[last_modified_operation])
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
           ,[comment_id]
           ,[da_reason_level1_id]
           ,[da_reason_level2_id]
           ,[da_reason_level3_id]
           ,[da_reason_level4_id]
           ,[disposition_plan_id]
           ,[disposition_type_id]
           ,[elapsed_time]
           ,[name]
           ,[quantity]
           ,[status]
		   ,[last_modified_operation]
		FROM Inserted
	END
END

GO
CREATE TRIGGER [ncr].[disposition_action_history_ins]
	ON  [ncr].[disposition_action]
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
	OR UPDATE([action_note]) 
	OR UPDATE([comment_id]) 
	OR UPDATE([da_reason_level1_id])
	OR UPDATE([da_reason_level2_id])
	OR UPDATE([da_reason_level3_id])
	OR UPDATE([da_reason_level4_id])
	OR UPDATE([elapsed_time])
	OR UPDATE([name])
	OR UPDATE([quantity])
	OR UPDATE([status]) 
	OR UPDATE([disposition_plan_id])
	OR UPDATE([disposition_type_id])
	OR UPDATE([id])
	OR UPDATE([last_modified_operation])) 
	BEGIN
		INSERT INTO disposition_action_history(
			[created_by]
           ,[created_on]
           ,[last_modified_by]
           ,[last_modified_on]
           ,[version]
           ,[column_updated_bitmask]
           ,[dbtt_id]
           ,[modified_on]
           ,[disposition_action_id]
           ,[comment_id]
           ,[da_reason_level1_id]
           ,[da_reason_level2_id]
           ,[da_reason_level3_id]
           ,[da_reason_level4_id]
           ,[disposition_plan_id]
           ,[disposition_type_id]
           ,[elapsed_time]
           ,[name]
           ,[quantity]
           ,[status]
		   ,[last_modified_operation])
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
           ,[comment_id]
           ,[da_reason_level1_id]
           ,[da_reason_level2_id]
           ,[da_reason_level3_id]
           ,[da_reason_level4_id]
           ,[disposition_plan_id]
           ,[disposition_type_id]
           ,[elapsed_time]
           ,[name]
           ,[quantity]
           ,[status]
		   ,[last_modified_operation]
		FROM Inserted
	END
END

GO
CREATE TRIGGER [ncr].[disposition_action_history_del]
	ON  [ncr].[disposition_action]
	FOR DELETE
AS 
BEGIN
	SET NOCOUNT ON
	IF (Context_info() = 0x446174615075726765) RETURN --DataPurge

	INSERT INTO disposition_action_history(
			[created_by]
           ,[created_on]
           ,[last_modified_by]
           ,[last_modified_on]
           ,[version]
           ,[column_updated_bitmask]
           ,[dbtt_id]
           ,[modified_on]
           ,[disposition_action_id]
           ,[comment_id]
           ,[da_reason_level1_id]
           ,[da_reason_level2_id]
           ,[da_reason_level3_id]
           ,[da_reason_level4_id]
           ,[disposition_plan_id]
           ,[disposition_type_id]
           ,[elapsed_time]
           ,[name]
           ,[quantity]
           ,[status]
		   ,[last_modified_operation])
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
           ,[comment_id]
           ,[da_reason_level1_id]
           ,[da_reason_level2_id]
           ,[da_reason_level3_id]
           ,[da_reason_level4_id]
           ,[disposition_plan_id]
           ,[disposition_type_id]
           ,[elapsed_time]
           ,[name]
           ,[quantity]
           ,[status]
		   ,[last_modified_operation]
		FROM deleted
END
