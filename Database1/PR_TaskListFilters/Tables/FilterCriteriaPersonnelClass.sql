CREATE TABLE [PR_TaskListFilters].[FilterCriteriaPersonnelClass] (
    [FilterCriteriaPersonnelClassKey] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PersonnelClassName]              NVARCHAR (200) NOT NULL,
    [FilterCriteriaKey]               BIGINT         NOT NULL,
    CONSTRAINT [PK_FilterCriteriaPersonnelClass] PRIMARY KEY CLUSTERED ([FilterCriteriaPersonnelClassKey] ASC),
    CONSTRAINT [FK_FilterCriteriaPersonnelClass_ComputerDmc] FOREIGN KEY ([PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]) ON DELETE CASCADE,
    CONSTRAINT [FK_FilterCriteriaPersonnelClass_FilterCriteria] FOREIGN KEY ([FilterCriteriaKey]) REFERENCES [PR_TaskListFilters].[FilterCriteria] ([FilterCriteriaKey]) ON DELETE CASCADE
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table relates Workflow task list filter criteria to personnel class instances.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaPersonnelClass';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identity key used as the primary key for this table.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaPersonnelClass', @level2type = N'COLUMN', @level2name = N'FilterCriteriaPersonnelClassKey';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Guid of the linked person used for the foreign key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaPersonnelClass', @level2type = N'COLUMN', @level2name = N'PersonnelClassName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identity key of the filter criteria record used for the foreign key.', @level0type = N'SCHEMA', @level0name = N'PR_TaskListFilters', @level1type = N'TABLE', @level1name = N'FilterCriteriaPersonnelClass', @level2type = N'COLUMN', @level2name = N'FilterCriteriaKey';

