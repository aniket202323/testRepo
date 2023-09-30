CREATE TABLE [PR_TaskListFilters].[FilterCriteriaInstance] (
    [FilterCriteriaInstanceKey] BIGINT           IDENTITY (1, 1) NOT NULL,
    [InstanceId]                UNIQUEIDENTIFIER NOT NULL,
    [FilterCriteriaKey]         BIGINT           NOT NULL,
    CONSTRAINT [PK_FilterCriteriaInstance] PRIMARY KEY CLUSTERED ([FilterCriteriaInstanceKey] ASC),
    CONSTRAINT [FK_FilterCriteriaInstance_FilterCriteria] FOREIGN KEY ([FilterCriteriaKey]) REFERENCES [PR_TaskListFilters].[FilterCriteria] ([FilterCriteriaKey]) ON DELETE CASCADE,
    CONSTRAINT [FK_FilterCriteriaInstance_Instance] FOREIGN KEY ([InstanceId]) REFERENCES [dbo].[Equipment] ([EquipmentId]) ON DELETE CASCADE
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table relates Workflow task list filter criteria to equipment instances.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaInstance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Integer used as the primary key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaInstance', @level2type = N'COLUMN', @level2name = N'FilterCriteriaInstanceKey';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifier of the associated instance record.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaInstance', @level2type = N'COLUMN', @level2name = N'InstanceId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identity key of the filter criteria record used for the foreign key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaInstance', @level2type = N'COLUMN', @level2name = N'FilterCriteriaKey';

