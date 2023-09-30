CREATE TABLE [dbo].[TaskListVisibilityIT] (
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
    [TaskListVisibilityITPkId]         UNIQUEIDENTIFIER NOT NULL,
    [Version]                          BIGINT           NULL,
    [Origin1ComputerDmcType]           NVARCHAR (255)   NULL,
    [Origin1ComputerDmcName]           NVARCHAR (255)   NULL,
    PRIMARY KEY CLUSTERED ([TaskListVisibilityITPkId] ASC),
    CONSTRAINT [TaskListVisibilityIT_ComputerDmc_Relation1] FOREIGN KEY ([Origin1ComputerDmcType], [Origin1ComputerDmcName]) REFERENCES [dbo].[ComputerDmc] ([ComputerDmcType], [ComputerDmcName]) ON UPDATE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaskListVisibilityIT_Origin1ComputerDmcType_Origin1ComputerDmcName]
    ON [dbo].[TaskListVisibilityIT]([Origin1ComputerDmcType] ASC, [Origin1ComputerDmcName] ASC);

