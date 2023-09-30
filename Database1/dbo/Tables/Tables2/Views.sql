CREATE TABLE [dbo].[Views] (
    [View_Id]          INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Group_Id]         INT                  NULL,
    [ShouldDelete]     TINYINT              NULL,
    [ToolBar_Data]     IMAGE                NULL,
    [Toolbar_Version]  VARCHAR (25)         NULL,
    [View_Data]        IMAGE                NULL,
    [View_Desc_Global] [dbo].[Varchar_Desc] NULL,
    [View_Desc_Local]  [dbo].[Varchar_Desc] NOT NULL,
    [View_Group_Id]    INT                  CONSTRAINT [DF_Views_View_Group_Id] DEFAULT ((1)) NULL,
    [View_Desc]        AS                   (case when (@@options&(512))=(0) then isnull([View_Desc_Global],[View_Desc_Local]) else [View_Desc_Local] end),
    CONSTRAINT [Views_PK_ViewId] PRIMARY KEY NONCLUSTERED ([View_Id] ASC),
    CONSTRAINT [View_FK_ViewGroupId] FOREIGN KEY ([View_Group_Id]) REFERENCES [dbo].[View_Groups] ([View_Group_Id]),
    CONSTRAINT [Views_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [Views_UC_ViewDescLocal] UNIQUE NONCLUSTERED ([View_Desc_Local] ASC)
);

