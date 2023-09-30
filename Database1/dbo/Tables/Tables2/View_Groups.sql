CREATE TABLE [dbo].[View_Groups] (
    [View_Group_Id]          INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Group_Id]               INT          NULL,
    [View_Group_Desc_Global] VARCHAR (50) NULL,
    [View_Group_Desc_Local]  VARCHAR (50) NOT NULL,
    [View_Group_Desc]        AS           (case when (@@options&(512))=(0) then isnull([View_Group_Desc_Global],[View_Group_Desc_Local]) else [View_Group_Desc_Local] end),
    CONSTRAINT [ViewGrps_PK_ShtGrpId] PRIMARY KEY CLUSTERED ([View_Group_Id] ASC),
    CONSTRAINT [ViewGroups_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [ViewGrps_UC_ViewGrpDescLocal] UNIQUE NONCLUSTERED ([View_Group_Desc_Local] ASC)
);

