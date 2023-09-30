CREATE TABLE [dbo].[DefaultClientLayoutDmc] (
    [SolutionPanelEnabled]          BIT            NULL,
    [NavigationPanelEnabled]        BIT            NULL,
    [StartupObjectEnabled]          BIT            NULL,
    [StartupSolutionDisplayEnabled] BIT            NULL,
    [StartupModel]                  NVARCHAR (255) NULL,
    [StartupEntryPoint]             NVARCHAR (255) NULL,
    [StartupObject]                 NVARCHAR (255) NULL,
    [StartupSolution]               NVARCHAR (255) NULL,
    [StartupDisplay]                NVARCHAR (255) NULL,
    [Version]                       BIGINT         NULL,
    [ComputerComputerDmcType]       NVARCHAR (255) NOT NULL,
    [ComputerComputerDmcName]       NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([ComputerComputerDmcType] ASC, [ComputerComputerDmcName] ASC),
    CONSTRAINT [DefaultClientLayoutDmc_ComputerDmc_Relation1] FOREIGN KEY ([ComputerComputerDmcType], [ComputerComputerDmcName]) REFERENCES [dbo].[ComputerDmc] ([ComputerDmcType], [ComputerDmcName])
);

