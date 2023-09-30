CREATE TABLE [PR_TaskListFilters].[FilterCriteria] (
    [FilterCriteriaKey]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [NameFilter]          NVARCHAR (80)  NULL,
    [PriorityFilter]      NVARCHAR (255) NULL,
    [MyStepsFilter]       BIT            NOT NULL,
    [ExpiresInFilter]     BIGINT         NULL,
    [ExpiresBeforeFilter] DATETIME       NULL,
    [StepStateFilter]     INT            NULL,
    CONSTRAINT [PK_FilterCriteria] PRIMARY KEY CLUSTERED ([FilterCriteriaKey] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table represents Workflow task list filter criteria details.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteria';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The string to filter task names against. ', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteria', @level2type = N'COLUMN', @level2name = N'NameFilter';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The priority values to filter tasks against. Can contain continuous and discontinuous ranges.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteria', @level2type = N'COLUMN', @level2name = N'PriorityFilter';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Set to indicate only steps assigned to the current context should match the filter.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteria', @level2type = N'COLUMN', @level2name = N'MyStepsFilter';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The time span relative to now to filter task and step expiry against', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteria', @level2type = N'COLUMN', @level2name = N'ExpiresInFilter';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The date time to filter task and step expiry against.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteria', @level2type = N'COLUMN', @level2name = N'ExpiresBeforeFilter';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'A bitmask of task step states to filter steps against.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteria', @level2type = N'COLUMN', @level2name = N'StepStateFilter';

