CREATE TABLE [dbo].[NPT_Detail_Grouping] (
    [NPT_Group_Id]   INT           IDENTITY (1, 1) NOT NULL,
    [NPT_Group_Desc] VARCHAR (100) NOT NULL,
    CONSTRAINT [NPTDetailGroup_PK_NTId] PRIMARY KEY CLUSTERED ([NPT_Group_Id] ASC),
    CONSTRAINT [NPTDetailGroup_UC_Desc] UNIQUE NONCLUSTERED ([NPT_Group_Desc] ASC)
);

