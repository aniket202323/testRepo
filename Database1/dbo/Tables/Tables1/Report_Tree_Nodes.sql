CREATE TABLE [dbo].[Report_Tree_Nodes] (
    [Node_Id]                 INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ForceRunMode]            TINYINT        NULL,
    [Node_Id_Type]            INT            NOT NULL,
    [Node_Level]              INT            NULL,
    [Node_Name]               VARCHAR (50)   NOT NULL,
    [Node_Order]              INT            NULL,
    [Parent_Node_Id]          INT            NULL,
    [Report_Def_Id]           INT            NULL,
    [Report_Tree_Template_Id] INT            NOT NULL,
    [Report_Type_Id]          INT            NULL,
    [SendParameters]          TINYINT        NULL,
    [URL]                     VARCHAR (7000) NULL,
    CONSTRAINT [PK___1__26] PRIMARY KEY CLUSTERED ([Node_Id] ASC),
    CONSTRAINT [FK_Report_Tree_Nodes_1__25] FOREIGN KEY ([Parent_Node_Id]) REFERENCES [dbo].[Report_Tree_Nodes] ([Node_Id]),
    CONSTRAINT [FK_Report_Tree_Nodes_2__11] FOREIGN KEY ([Report_Type_Id]) REFERENCES [dbo].[Report_Types] ([Report_Type_Id]),
    CONSTRAINT [FK_Report_Tree_Nodes_3__11] FOREIGN KEY ([Report_Tree_Template_Id]) REFERENCES [dbo].[Report_Tree_Templates] ([Report_Tree_Template_Id]),
    CONSTRAINT [FK_Report_Tree_Nodes_Report_Tree_Node_Types] FOREIGN KEY ([Node_Id_Type]) REFERENCES [dbo].[Report_Tree_Node_Types] ([Node_Type_Id]),
    CONSTRAINT [ReportTreeNodes_FK_ReportId] FOREIGN KEY ([Report_Def_Id]) REFERENCES [dbo].[Report_Definitions] ([Report_Id])
);

