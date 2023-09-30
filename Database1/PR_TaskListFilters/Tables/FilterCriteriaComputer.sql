CREATE TABLE [PR_TaskListFilters].[FilterCriteriaComputer] (
    [FilterCriteriaComputerKey] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ComputerType]              NVARCHAR (255) DEFAULT ('Computer') NOT NULL,
    [ComputerName]              NVARCHAR (255) NOT NULL,
    [FilterCriteriaKey]         BIGINT         NOT NULL,
    CONSTRAINT [PK_FilterCriteriaComputer] PRIMARY KEY CLUSTERED ([FilterCriteriaComputerKey] ASC),
    CONSTRAINT [FK_FilterCriteriaComputer_ComputerDmc] FOREIGN KEY ([ComputerType], [ComputerName]) REFERENCES [dbo].[ComputerDmc] ([ComputerDmcType], [ComputerDmcName]) ON DELETE CASCADE,
    CONSTRAINT [FK_FilterCriteriaComputer_FilterCriteria] FOREIGN KEY ([FilterCriteriaKey]) REFERENCES [PR_TaskListFilters].[FilterCriteria] ([FilterCriteriaKey]) ON DELETE CASCADE
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table relates Workflow task list filter criteria to computer instances.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaComputer';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Integer used as the primary key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaComputer', @level2type = N'COLUMN', @level2name = N'FilterCriteriaComputerKey';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type of the associated computer.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaComputer', @level2type = N'COLUMN', @level2name = N'ComputerType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Name of the associated computer.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaComputer', @level2type = N'COLUMN', @level2name = N'ComputerName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identity key of the filter criteria record used for the foreign key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaComputer', @level2type = N'COLUMN', @level2name = N'FilterCriteriaKey';

