CREATE TABLE [PR_TaskListFilters].[AppliedPredefinedFilters] (
    [LinkKey]            BIGINT           IDENTITY (1, 1) NOT NULL,
    [UserId]             UNIQUEIDENTIFIER NOT NULL,
    [PredefinedFilterId] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_AppliedPredefinedFilters] PRIMARY KEY CLUSTERED ([LinkKey] ASC),
    CONSTRAINT [FK_AppliedPredefinedFilters_Person] FOREIGN KEY ([UserId]) REFERENCES [PR_Authorization].[Person] ([PersonId]) ON DELETE CASCADE,
    CONSTRAINT [FK_AppliedPredefinedFilters_PredefinedFilter] FOREIGN KEY ([PredefinedFilterId]) REFERENCES [PR_TaskListFilters].[PredefinedFilters] ([FiltersId]) ON DELETE CASCADE
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table contains the saved details of applied Workflow task list predefined filters.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'AppliedPredefinedFilters';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'BIGINT identifier used as primary key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'AppliedPredefinedFilters', @level2type = N'COLUMN', @level2name = N'LinkKey';

