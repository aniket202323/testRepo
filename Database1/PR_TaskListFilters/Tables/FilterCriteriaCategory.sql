CREATE TABLE [PR_TaskListFilters].[FilterCriteriaCategory] (
    [FilterCriteriaCategoryKey] BIGINT           IDENTITY (1, 1) NOT NULL,
    [CategoryId]                UNIQUEIDENTIFIER NOT NULL,
    [CategoryRevision]          BIGINT           DEFAULT ((1)) NOT NULL,
    [FilterCriteriaKey]         BIGINT           NOT NULL,
    CONSTRAINT [PK_FilterCriteriaCategory] PRIMARY KEY CLUSTERED ([FilterCriteriaCategoryKey] ASC),
    CONSTRAINT [FK_FilterCriteriaCategory_CategoryDefinition] FOREIGN KEY ([CategoryId], [CategoryRevision]) REFERENCES [dbo].[CategoryDefinition] ([CategoryDefinitionId], [CategoryDefinitionRevision]) ON DELETE CASCADE,
    CONSTRAINT [FK_FilterCriteriaCategory_FilterCriteria] FOREIGN KEY ([FilterCriteriaKey]) REFERENCES [PR_TaskListFilters].[FilterCriteria] ([FilterCriteriaKey]) ON DELETE CASCADE
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table relates Workflow task list filter criteria to category definitions.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaCategory';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identity key used as the primary key for this table.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaCategory', @level2type = N'COLUMN', @level2name = N'FilterCriteriaCategoryKey';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Guid of the linked category definition used for the foreign key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaCategory', @level2type = N'COLUMN', @level2name = N'CategoryId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Revision of the linked category definition used for the foreign key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaCategory', @level2type = N'COLUMN', @level2name = N'CategoryRevision';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identity key of the filter criteria record used for the foreign key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaCategory', @level2type = N'COLUMN', @level2name = N'FilterCriteriaKey';

