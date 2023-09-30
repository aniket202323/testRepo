CREATE TABLE [PR_TaskListFilters].[QuickFilters] (
    [FilterKey]         BIGINT           IDENTITY (1, 1) NOT NULL,
    [UserId]            UNIQUEIDENTIFIER NOT NULL,
    [FilterCriteriaKey] BIGINT           NULL,
    [Enabled]           BIT              DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_QuickFilters] PRIMARY KEY CLUSTERED ([FilterKey] ASC),
    CONSTRAINT [FK_QuickFilters_FilterCriteria] FOREIGN KEY ([FilterCriteriaKey]) REFERENCES [PR_TaskListFilters].[FilterCriteria] ([FilterCriteriaKey]),
    CONSTRAINT [FK_QuickFilters_Person] FOREIGN KEY ([UserId]) REFERENCES [PR_Authorization].[Person] ([PersonId]) ON DELETE CASCADE
);


GO

/* OVERVIEW
 * After Trigger for DELETE FROM [PR_TaskListFilters.QuickFilters]
 * This trigger deletes all linked filter criteria rows of a Quick Filter instance.
 * END OVERVIEW */

CREATE TRIGGER [PR_TaskListFilters].[trg_QuickFilterCriteriaDelete]
ON [PR_TaskListFilters].QuickFilters
FOR DELETE
AS 
BEGIN
	DECLARE
		@rec_deleted  INTEGER,
		@Routine VARCHAR(100),
		@rowsDeleted INTEGER,
		@debug BIT = 0 -- set to 1 to display debug statements

	SET NOCOUNT ON

   SET @Routine = 'trg_QuickFilterCriteriaDelete'
	SELECT @rec_deleted = COUNT(*)
	 FROM deleted

	-- check that we really got a delete 
	IF (@rec_deleted = 0)
	BEGIN
		IF (@debug = 1) PRINT @Routine + ': No filter criteria records to delete'
		RETURN
	END

	-- CLAIM: We have a valid delete that we need to process

	-- Delete all filter criteria rows that match personal filters filter criteris key column in deleted set and 
	-- all filtesr rows that match personal filters key column in deleted set
	
	DELETE FROM [PR_TaskListFilters].[FilterCriteria] 
		WHERE FilterCriteriaKey IN (SELECT FilterCriteriaKey FROM deleted)
		
	 SELECT @rowsDeleted = @@ROWCOUNT
	 IF (@debug = 1) PRINT @Routine + ': Filter Criteria records deleted: ' + CONVERT(VARCHAR(5),@rowsDeleted)

/* done */
END
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table contains details of saved Workflow task list quick filters.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'QuickFilters';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Guid identifier used as primary key and import/export.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'QuickFilters', @level2type = N'COLUMN', @level2name = N'FilterKey';

