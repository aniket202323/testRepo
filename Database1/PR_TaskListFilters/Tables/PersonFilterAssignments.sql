CREATE TABLE [PR_TaskListFilters].[PersonFilterAssignments] (
    [PersonFilterAssignmentsKey] BIGINT           IDENTITY (1, 1) NOT NULL,
    [PersonId]                   UNIQUEIDENTIFIER NOT NULL,
    [FilterId]                   UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_PersonFilterAssignments] PRIMARY KEY CLUSTERED ([PersonFilterAssignmentsKey] ASC),
    CONSTRAINT [FK_PersonFilterAssignments_Person] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]) ON DELETE CASCADE,
    CONSTRAINT [FK_PersonFilterAssignments_PredefinedFilters] FOREIGN KEY ([FilterId]) REFERENCES [PR_TaskListFilters].[PredefinedFilters] ([FiltersId]) ON DELETE CASCADE
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table relates Workflow task list filters to person instances.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PersonFilterAssignments';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Integer identifier used as primary key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PersonFilterAssignments', @level2type = N'COLUMN', @level2name = N'PersonFilterAssignmentsKey';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Related person id.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PersonFilterAssignments', @level2type = N'COLUMN', @level2name = N'PersonId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Related filter id.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PersonFilterAssignments', @level2type = N'COLUMN', @level2name = N'FilterId';

