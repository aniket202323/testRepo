CREATE TABLE [dbo].[Report_Tree_Node_Types] (
    [Node_Type_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Node_Type_Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Report_Tree_Node_Types] PRIMARY KEY NONCLUSTERED ([Node_Type_Id] ASC)
);

