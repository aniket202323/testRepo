CREATE TABLE [dbo].[Report_Shortcuts] (
    [Report_Shortcut_Id] INT           IDENTITY (1, 1) NOT NULL,
    [App_Id]             INT           NOT NULL,
    [Document_Name]      VARCHAR (100) NULL,
    [PU_Id]              INT           NULL,
    [Report_Name]        VARCHAR (25)  NULL,
    CONSTRAINT [Rpt_Shortcuts_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);

