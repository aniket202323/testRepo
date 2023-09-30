CREATE TABLE [PR_TaskListFilters].[ComputerFilterAssignments] (
    [ComputerFilterAssignmentsKey] BIGINT           IDENTITY (1, 1) NOT NULL,
    [ComputerType]                 NVARCHAR (255)   NOT NULL,
    [ComputerName]                 NVARCHAR (255)   NOT NULL,
    [FilterId]                     UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_ComputerFilterAssignments] PRIMARY KEY CLUSTERED ([ComputerFilterAssignmentsKey] ASC),
    CONSTRAINT [FK_ComputerFilterAssignments_ComputerDmc] FOREIGN KEY ([ComputerType], [ComputerName]) REFERENCES [dbo].[ComputerDmc] ([ComputerDmcType], [ComputerDmcName]) ON DELETE CASCADE,
    CONSTRAINT [FK_ComputerFilterAssignments_PredefinedFilters] FOREIGN KEY ([FilterId]) REFERENCES [PR_TaskListFilters].[PredefinedFilters] ([FiltersId]) ON DELETE CASCADE
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table relates Workflow task list filters to computer instances.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'ComputerFilterAssignments';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Integer identifier used as primary key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'ComputerFilterAssignments', @level2type = N'COLUMN', @level2name = N'ComputerFilterAssignmentsKey';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Related computer type.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'ComputerFilterAssignments', @level2type = N'COLUMN', @level2name = N'ComputerType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Related computer name.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'ComputerFilterAssignments', @level2type = N'COLUMN', @level2name = N'ComputerName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Related filter id.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'ComputerFilterAssignments', @level2type = N'COLUMN', @level2name = N'FilterId';

