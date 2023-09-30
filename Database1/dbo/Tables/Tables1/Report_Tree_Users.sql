CREATE TABLE [dbo].[Report_Tree_Users] (
    [NTUserId]                VARCHAR (100) NULL,
    [Report_Tree_Template_Id] INT           NOT NULL,
    [User_Id]                 INT           NOT NULL,
    [User_Rights]             INT           CONSTRAINT [DF_Report_Tre_User_Rights2__24] DEFAULT ((0)) NULL,
    [View_Setting]            INT           CONSTRAINT [DF_Report_Tre_View_Settin1__24] DEFAULT ((0)) NULL,
    CONSTRAINT [PK___1__28] PRIMARY KEY CLUSTERED ([User_Id] ASC),
    CONSTRAINT [FK_Report_Tree_Users_Report_Tree_Templates] FOREIGN KEY ([Report_Tree_Template_Id]) REFERENCES [dbo].[Report_Tree_Templates] ([Report_Tree_Template_Id])
);

