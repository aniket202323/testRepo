CREATE TABLE [dbo].[Report_Parameter_Groups] (
    [Group_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Group_Name] VARCHAR (20) NOT NULL,
    [Group_Type] INT          NULL,
    CONSTRAINT [PK_Report_Parameter_Groups] PRIMARY KEY NONCLUSTERED ([Group_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Report_Parameter_Groups_UX_Name]
    ON [dbo].[Report_Parameter_Groups]([Group_Name] ASC);

