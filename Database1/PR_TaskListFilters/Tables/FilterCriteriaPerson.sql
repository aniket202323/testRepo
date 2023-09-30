CREATE TABLE [PR_TaskListFilters].[FilterCriteriaPerson] (
    [FilterCriteriaPersonKey] BIGINT           IDENTITY (1, 1) NOT NULL,
    [PersonId]                UNIQUEIDENTIFIER NOT NULL,
    [FilterCriteriaKey]       BIGINT           NOT NULL,
    CONSTRAINT [PK_FilterCriteriaPerson] PRIMARY KEY CLUSTERED ([FilterCriteriaPersonKey] ASC),
    CONSTRAINT [FK_FilterCriteriaPerson_FilterCriteria] FOREIGN KEY ([FilterCriteriaKey]) REFERENCES [PR_TaskListFilters].[FilterCriteria] ([FilterCriteriaKey]) ON DELETE CASCADE,
    CONSTRAINT [FK_FilterCriteriaPerson_Person] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]) ON DELETE CASCADE
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table relates Workflow task list filter criteria to person instances.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaPerson';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identity key used as the primary key for this table.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaPerson', @level2type = N'COLUMN', @level2name = N'FilterCriteriaPersonKey';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Guid of the linked person used for the foreign key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaPerson', @level2type = N'COLUMN', @level2name = N'PersonId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identity key of the filter criteria record used for the foreign key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaPerson', @level2type = N'COLUMN', @level2name = N'FilterCriteriaKey';

