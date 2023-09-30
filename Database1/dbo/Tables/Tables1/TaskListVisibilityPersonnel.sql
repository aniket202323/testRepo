CREATE TABLE [dbo].[TaskListVisibilityPersonnel] (
    [TaskTitleVisibility]              BIT              NULL,
    [TaskGridVisibility]               BIT              NULL,
    [TaskContextNavVisibility]         BIT              NULL,
    [TaskStepListVisibility]           BIT              NULL,
    [TaskStepContextNavVisibility]     BIT              NULL,
    [StatusMessageVisibility]          BIT              NULL,
    [ReleaseTaskStepsDialogVisibility] BIT              NULL,
    [DisplayModeVisibility]            BIT              NULL,
    [TaskListContextVisibility]        BIT              NULL,
    [TaskListContextEnabled]           BIT              NULL,
    [InputVisibility]                  BIT              NULL,
    [DetailsVisibility]                BIT              NULL,
    [ActionsVisibility]                BIT              NULL,
    [FiltersVisibility]                BIT              NULL,
    [StartTaskVisibility]              BIT              NULL,
    [StepLayoutVisibility]             BIT              NULL,
    [FontSizeVisibility]               BIT              NULL,
    [TaskListVisibilityPersonnelPkId]  UNIQUEIDENTIFIER NOT NULL,
    [Version]                          BIGINT           NULL,
    [Origin1PersonnelClassName]        NVARCHAR (200)   NULL,
    PRIMARY KEY CLUSTERED ([TaskListVisibilityPersonnelPkId] ASC),
    CONSTRAINT [TaskListVisibilityPersonnel_PersonnelClass_Relation1] FOREIGN KEY ([Origin1PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]) ON UPDATE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaskListVisibilityPersonnel_Origin1PersonnelClassName]
    ON [dbo].[TaskListVisibilityPersonnel]([Origin1PersonnelClassName] ASC);

