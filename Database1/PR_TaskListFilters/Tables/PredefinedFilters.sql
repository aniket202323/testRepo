CREATE TABLE [PR_TaskListFilters].[PredefinedFilters] (
    [FiltersId]         UNIQUEIDENTIFIER NOT NULL,
    [Name]              NVARCHAR (255)   NOT NULL,
    [Description]       NVARCHAR (255)   NULL,
    [FilterCriteriaKey] BIGINT           NULL,
    CONSTRAINT [PK_PredefinedFilters] PRIMARY KEY CLUSTERED ([FiltersId] ASC),
    CONSTRAINT [FK_PredefinedFilters_FilterCriteria] FOREIGN KEY ([FilterCriteriaKey]) REFERENCES [PR_TaskListFilters].[FilterCriteria] ([FilterCriteriaKey]),
    CONSTRAINT [UC_PredefinedFilters_Name] UNIQUE NONCLUSTERED ([Name] ASC)
);


GO

/* OVERVIEW
 * After Trigger for DELETE FROM [PR_TaskListFilters.PredefinedFilters]
 * This trigger deletes all linked filter criteria rows of a Predefined Filter instance.
 * END OVERVIEW */

CREATE TRIGGER [PR_TaskListFilters].[trg_PredefinedFilterCriteriaDelete]
ON [PR_TaskListFilters].PredefinedFilters
FOR DELETE
AS 
BEGIN
	DECLARE
		@rec_deleted  INTEGER,
		@Routine VARCHAR(100),
		@rowsDeleted INTEGER,
		@debug BIT = 0 -- set to 1 to display debug statements

	SET NOCOUNT ON

   SET @Routine = 'trg_PredefinedFilterCriteriaDelete'
	SELECT @rec_deleted = COUNT(*)
	 FROM deleted

	-- check that we really got a delete 
	IF (@rec_deleted = 0)
	BEGIN
		IF (@debug = 1) PRINT @Routine + ': No filter criteria records to delete'
		RETURN
	END

	-- CLAIM: We have a valid delete that we need to process

	-- Delete all filter criteria rows that match Predefined filters filter criteris key column in deleted set and 
	-- all filtesr rows that match Predefined filters key column in deleted set
	
	DELETE FROM [PR_TaskListFilters].[FilterCriteria] 
		WHERE FilterCriteriaKey IN (SELECT FilterCriteriaKey FROM deleted)
		
	 SELECT @rowsDeleted = @@ROWCOUNT
	 IF (@debug = 1) PRINT @Routine + ': Filter Criteria records deleted: ' + CONVERT(VARCHAR(5),@rowsDeleted)

/* done */
END
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table contains details of Workflow task list predefined filters.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PredefinedFilters';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Guid identifier used as primary key and import/export.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PredefinedFilters', @level2type = N'COLUMN', @level2name = N'FiltersId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Unique filter name.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PredefinedFilters', @level2type = N'COLUMN', @level2name = N'Name';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Optional filter description.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PredefinedFilters', @level2type = N'COLUMN', @level2name = N'Description';

