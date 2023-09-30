CREATE TABLE [PR_TaskListFilters].[InstanceFilterAssignments] (
    [InstanceFilterAssignmentsKey] BIGINT           IDENTITY (1, 1) NOT NULL,
    [InstanceId]                   UNIQUEIDENTIFIER NOT NULL,
    [FilterId]                     UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_InstanceFilterAssignments] PRIMARY KEY CLUSTERED ([InstanceFilterAssignmentsKey] ASC),
    CONSTRAINT [FK_InstanceFilterAssignments_Instance] FOREIGN KEY ([InstanceId]) REFERENCES [dbo].[Equipment] ([EquipmentId]) ON DELETE CASCADE,
    CONSTRAINT [FK_InstanceFilterAssignments_PredefinedFilters] FOREIGN KEY ([FilterId]) REFERENCES [PR_TaskListFilters].[PredefinedFilters] ([FiltersId]) ON DELETE CASCADE
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table relates Workflow task list filters to equipment instances.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'InstanceFilterAssignments';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Integer identifier used as primary key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'InstanceFilterAssignments', @level2type = N'COLUMN', @level2name = N'InstanceFilterAssignmentsKey';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Related equipment instance id.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'InstanceFilterAssignments', @level2type = N'COLUMN', @level2name = N'InstanceId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Related filter id.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'InstanceFilterAssignments', @level2type = N'COLUMN', @level2name = N'FilterId';

