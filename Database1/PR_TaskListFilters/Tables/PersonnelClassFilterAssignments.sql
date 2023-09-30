CREATE TABLE [PR_TaskListFilters].[PersonnelClassFilterAssignments] (
    [PersonnelClassFilterAssignmentsKey] BIGINT           IDENTITY (1, 1) NOT NULL,
    [PersonnelClassName]                 NVARCHAR (200)   NOT NULL,
    [FilterId]                           UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_PersonnelClassFilterAssignments] PRIMARY KEY CLUSTERED ([PersonnelClassFilterAssignmentsKey] ASC),
    CONSTRAINT [FK_PersonnelClassFilterAssignments_PersonnelClass] FOREIGN KEY ([PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]) ON DELETE CASCADE,
    CONSTRAINT [FK_PersonnelClassFilterAssignments_PredefinedFilters] FOREIGN KEY ([FilterId]) REFERENCES [PR_TaskListFilters].[PredefinedFilters] ([FiltersId]) ON DELETE CASCADE
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table relates Workflow task list filters to personnel class instances.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PersonnelClassFilterAssignments';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Integer identifier used as primary key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PersonnelClassFilterAssignments', @level2type = N'COLUMN', @level2name = N'PersonnelClassFilterAssignmentsKey';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Related personnel class name.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PersonnelClassFilterAssignments', @level2type = N'COLUMN', @level2name = N'PersonnelClassName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Related filter id.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'PersonnelClassFilterAssignments', @level2type = N'COLUMN', @level2name = N'FilterId';

